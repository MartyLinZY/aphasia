"""JiangLin 语料解析的纯单元测试（chat_corpus）——不调 API、不依赖模型。

注：原困惑度(BERT)相关测试已随 perplexity.py 一并移除。
特征法在真实语料上的质量验证见 validate_features.py（需 API，非 pytest），
分类指标回归见 test_features_regression.py（读缓存，离线）。
"""
import pytest

from chat_corpus import corpus_available, extract_par_sentences, extract_dialogue, list_corpus

pytestmark = pytest.mark.skipif(
    not corpus_available(),
    reason="JiangLin 语料未就绪（设 CORPUS_PATH 或放到仓库同级 JiangLin/）",
)


def test_real_pwa_sentences_extractable():
    """真实 PWA 文件能抽出患者语句（纯汉字清洗没坏）。"""
    files = list_corpus("PWA", limit_files=3)
    total = sum(len(extract_par_sentences(f)) for f in files)
    assert total > 0, "一条患者语句都没抽到 —— .cha 格式或解析器出问题"


def test_dialogue_extraction_strips_annotations():
    """extract_dialogue 产出 INV:/PAR: 对话，且剥掉时间戳/CLAN 码/morpho 行。"""
    d = extract_dialogue(list_corpus("PWA", limit_files=1)[0])
    lines = d.splitlines()
    assert lines, "对话为空"
    assert all(ln.startswith("INV:") or ln.startswith("PAR:") for ln in lines), "混入了非对话行"
    assert "%mor" not in d and "%gra" not in d, "morpho/依存标注行没被剥掉"
    assert "_" not in d.replace("INV:", "").replace("PAR:", ""), "时间戳没剥干净"
