//
//  VideoHardEncoder.h
//  RtmpClient
//
//  Created by  Max on 07/27/2017.
//  Copyright © 2017 net.qdating. All rights reserved.
//  视频硬解码实现类

#ifndef VideoHardEncoder_h
#define VideoHardEncoder_h

#include <AndroidCommon/JniCommonFunc.h>

#include <rtmpdump/IEncoder.h>
#include <rtmpdump/VideoFrame.h>

#include <common/KThread.h>

namespace coollive {
class EncodeVideoHardRunnable;
class RtmpPublisher;
class VideoHardEncoder : public VideoEncoder {
public:
	VideoHardEncoder();
	VideoHardEncoder(jobject jniEncoder);
    virtual ~VideoHardEncoder();

public:
    bool Create(VideoEncoderCallback* callback, int width, int height, int bitRate, int keyFrameInterval, int fps);
    bool Reset();
    void Pause();
    void EncodeVideoFrame(void* data, int size, void* frame);
    
private:
    /**
     * 初始化
     */
    void Init();
    /**
     * 停止
     */
    void Stop();
    /**
     * 处理一个编码帧
     */
    void HandleVideoFrame(JNIEnv* env, jclass jniEncoderCls, jobject jVideoFrame);

private:
    // 编码线程实现体
    friend class EncodeVideoHardRunnable;
    void EncodeVideoHandle();

private:
    VideoEncoderCallback* mpCallback;
    jobject mJniEncoder;

    // 编码器变量
    int mWidth;
    int mHeight;
    int mBitRate;
    int mKeyFrameInterval;
    int mFPS;

    jbyteArray dataByteArray;

    // 编码线程
    KThread mEncodeVideoThread;
    EncodeVideoHardRunnable* mpEncodeVideoRunnable;
    // 状态锁
    KMutex mRuningMutex;
    bool mbRunning;

    // 空闲Buffer
    EncodeDecodeBufferList mFreeBufferList;
};
}

#endif /* VideoHardEncoder_h */