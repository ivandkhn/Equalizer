//
//  ChoirDSP.hpp
//  Equalizer
//
//  Created by Иван Дахненко on 05/03/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

#pragma once

#import <AVFoundation/AVFoundation.h>
#import "AKParameterRamp.hpp"
#import "AKExponentialParameterRamp.hpp"

typedef NS_ENUM(AUParameterAddress, AKBoosterParameter) {
    AKBoosterParameterLeftGain,
    AKBoosterParameterRightGain,
    AKBoosterParameterRampDuration,
    AKBoosterParameterRampType
};

#ifndef __cplusplus

void *createChoirDSP(int nChannels, double sampleRate);

#else

#import "AKDSPBase.hpp"

struct ChoirDSP : AKDSPBase {

private:
    struct _Internal;
    std::unique_ptr<_Internal> _private;

public:
    ChoirDSP();

    void setParameter(AUParameterAddress address, float value, bool immediate) override;
    float getParameter(AUParameterAddress address) override;
    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override;
};

#endif
