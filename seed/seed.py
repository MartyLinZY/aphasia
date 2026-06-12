#!/usr/bin/env python3
"""演示种子数据生成器（走后端真实 API）。

关键：后端 POST /api/exams 只建套题骨架（分类/子项/诊断规则），
**不持久化内嵌题目**——它只取每个 QuestionDto 的 id 当引用
（见 ExamMapper：model.setQuestions(dto.getQuestions().map(q -> q.getId()))）。
所以题目必须逐个走 POST /api/exams/{id}/categories/{ci}/subCategories/{si}/question
（addQuestion 会 questionDao.save 建题 + addQuestionIntoExam 追加 ID）。

用法：
    docker compose up -d            # 先把 mongo + backend 起来
    python3 seed/seed.py            # 幂等：账号已存在自动改登录
环境变量可覆盖：BACKEND_URL / DEMO_DOCTOR(_PW) / DEMO_PATIENT(_PW)
"""
import copy
import json
import os
import sys
import urllib.error
import urllib.request

BASE = os.environ.get("BACKEND_URL", "http://localhost:8080").rstrip("/")
HERE = os.path.dirname(os.path.abspath(__file__))
# 可选 argv[1] 指定套题文件（默认 exam.json）；如 ./seed.sh exam_reliable.json
_arg = sys.argv[1] if len(sys.argv) > 1 else "exam.json"
EXAM_JSON = _arg if os.path.isabs(_arg) else os.path.join(HERE, _arg)

# 注意：前端登录表单（login.dart:_validateUsername）校验 identity 必须是
# 中国手机号 ^1[3-9]\d{9}$ 或邮箱，否则客户端直接拦截。所以演示账号用手机号，
# 不能用 demo_doctor 这种任意串（后端不挑，但 GUI 登不进去）。
DOCTOR = os.environ.get("DEMO_DOCTOR", "13800000002")
DOCTOR_PW = os.environ.get("DEMO_DOCTOR_PW", "demo1234")
PATIENT = os.environ.get("DEMO_PATIENT", "13800000001")
PATIENT_PW = os.environ.get("DEMO_PATIENT_PW", "demo1234")


def _req(method, path, body=None, headers=None):
    url = BASE + path
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        raise RuntimeError(f"{method} {path} -> HTTP {e.code}: {raw}") from None
    return json.loads(raw) if raw.strip() else {}


def register_or_login(identity, password, role):
    # 先登录后注册：后端 DatabaseInitializer 给 user.identity 建了唯一索引，register-first
    # 在账号已存在时会失败/冲突。login-first 让脚本幂等、复用同一 uid，避免演示数据分散到多个账号。
    try:
        r = _req("POST", "/api/auth", None,
                 {"identity": identity, "password": password})
        if r.get("token"):
            return r["token"]
    except RuntimeError:
        pass  # 账号不存在 → 去注册
    r = _req("POST", "/api/register",
             {"identity": identity, "password": password, "role": role})
    if not r.get("token"):
        sys.exit(f"❌ {identity} 登录/注册均失败")
    return r["token"]


def main():
    with open(EXAM_JSON, encoding="utf-8") as f:
        exam = json.load(f)

    print(f"▶ 后端：{BASE}")
    print(f"▶ 建医生账号 {DOCTOR} ...")
    dtok = register_or_login(DOCTOR, DOCTOR_PW, 2)
    auth = {"Token": dtok}
    print("  ✅ 医生就绪")

    print(f"▶ 建患者账号 {PATIENT} ...")
    register_or_login(PATIENT, PATIENT_PW, 1)
    print("  ✅ 患者就绪")

    # 1) 骨架：把每个子项的题目摘出来另存，子项先置空
    skeleton = copy.deepcopy(exam)
    pending = []  # (categoryIndex, subCategoryIndex, question)
    for ci, cat in enumerate(skeleton.get("categories", [])):
        for si, sub in enumerate(cat.get("subCategories", [])):
            for q in sub.get("questions", []):
                q = copy.deepcopy(q)
                q.pop("id", None)
                pending.append((ci, si, q))
            sub["questions"] = []
    skeleton.pop("id", None)

    print("▶ 创建套题骨架（POST /api/exams）...")
    created = _req("POST", "/api/exams", skeleton, auth)
    exam_id = created.get("id")
    if not exam_id:
        sys.exit(f"❌ 创建骨架失败：{created}")
    print(f"  ✅ 骨架已建，examId={exam_id}")

    print(f"▶ 逐题写入（{len(pending)} 题）...")
    for ci, si, q in pending:
        path = f"/api/exams/{exam_id}/categories/{ci}/subCategories/{si}/question"
        _req("POST", path, q, auth)
        print(f"    ＋ [{q.get('typeName')}] {q.get('alias')}")

    print(f"▶ 发布套题（PATCH /api/exams/{exam_id}）...")
    _req("PATCH", f"/api/exams/{exam_id}", None, auth)
    print("  ✅ 已发布")

    print("\n🎉 种子数据就绪")
    print(f"   医生：{DOCTOR} / {DOCTOR_PW}   （role 2）")
    print(f"   患者：{PATIENT} / {PATIENT_PW}  （role 1）")
    print(f"   套题：{exam['name']}（examId={exam_id}，{len(pending)} 题，含诊断规则）")
    print("   题目图片来自前端 asset，无需 seed 后端文件。")
    print("\n下一步（做成开机即演示的交付包）：")
    print("   docker compose exec mongo mongodump --out /tmp/seed-dump")
    print("   docker compose cp mongo:/tmp/seed-dump ./seed/mongodump")
    print("   # 目标机首启动时 seed/restore.sh 会自动 mongorestore（见 seed/README.md）")


if __name__ == "__main__":
    main()
