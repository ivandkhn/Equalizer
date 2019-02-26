//
//  DistortionDSP.hpp
//  Equalizer
//
//  Created by Иван Дахненко on 25/02/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

#pragma once

#import <AVFoundation/AVFoundation.h>
#import "AKParameterRamp.hpp"
#import "AKExponentialParameterRamp.hpp" // to be deleted

typedef NS_ENUM(AUParameterAddress, DistortionParameter) {
    DistortionParameterLeftGain,
    DistortionParameterRightGain,
    DistortionParameterRampDuration,
    DistortionParameterRampType
};

#ifndef __cplusplus

void *createDistortionDSP(int nChannels, double sampleRate);

#else

#import "AKDSPBase.hpp"

/**
 A simple DSP kernel. Most of the plumbing is in the base class. All the code at this
 level has to do is supply the core of the rendering code. A less trivial example would probably
 need to coordinate the updating of DSP parameters, which would probably involve thread locks,
 etc.
 */

struct DistortionDSP : AKDSPBase {

private:
    struct _Internal;
    std::unique_ptr<_Internal> _private;

public:
    DistortionDSP();

    void setParameter(AUParameterAddress address, float value, bool immediate) override;
    float getParameter(AUParameterAddress address) override;
    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override;
};

#endif
