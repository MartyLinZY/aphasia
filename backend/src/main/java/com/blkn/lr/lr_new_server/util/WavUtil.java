package com.blkn.lr.lr_new_server.util;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * raw PCM (16-bit signed little-endian, mono) → WAV (RIFF/WAVE)
 * 仅用于把前端上传的裸 PCM 包成 WAV 后投喂给多模态模型。
 */
public class WavUtil {
    private WavUtil() {}

    private static final int DEFAULT_SAMPLE_RATE = 16000;
    private static final int DEFAULT_BITS_PER_SAMPLE = 16;
    private static final int DEFAULT_CHANNELS = 1;

    public static byte[] pcm16kMonoToWav(byte[] pcm) {
        return pcmToWav(pcm, DEFAULT_SAMPLE_RATE, DEFAULT_CHANNELS, DEFAULT_BITS_PER_SAMPLE);
    }

    public static byte[] pcmToWav(byte[] pcm, int sampleRate, int channels, int bitsPerSample) {
        int byteRate = sampleRate * channels * bitsPerSample / 8;
        int blockAlign = channels * bitsPerSample / 8;
        int dataSize = pcm.length;
        int chunkSize = 36 + dataSize;

        ByteBuffer buf = ByteBuffer.allocate(44 + dataSize).order(ByteOrder.LITTLE_ENDIAN);
        buf.put((byte) 'R').put((byte) 'I').put((byte) 'F').put((byte) 'F');
        buf.putInt(chunkSize);
        buf.put((byte) 'W').put((byte) 'A').put((byte) 'V').put((byte) 'E');
        buf.put((byte) 'f').put((byte) 'm').put((byte) 't').put((byte) ' ');
        buf.putInt(16);
        buf.putShort((short) 1);
        buf.putShort((short) channels);
        buf.putInt(sampleRate);
        buf.putInt(byteRate);
        buf.putShort((short) blockAlign);
        buf.putShort((short) bitsPerSample);
        buf.put((byte) 'd').put((byte) 'a').put((byte) 't').put((byte) 'a');
        buf.putInt(dataSize);
        buf.put(pcm);
        return buf.array();
    }
}
