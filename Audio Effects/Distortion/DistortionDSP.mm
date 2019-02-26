//
//  DistortionDSP.mm
//  Equalizer
//
//  Created by Иван Дахненко on 25/02/2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

#include "DistortionDSP.hpp"

extern "C" void *createDistortionDSP(int nChannels, double sampleRate) {
    DistortionDSP *dsp = new DistortionDSP();
    dsp->init(nChannels, sampleRate);
    return dsp;
}

struct DistortionDSP::_Internal {
    AKParameterRamp leftGainRamp;
    AKParameterRamp rightGainRamp;
};

DistortionDSP::DistortionDSP() : _private(new _Internal) {
    _private->leftGainRamp.setTarget(1.0, true);
    _private->leftGainRamp.setDurationInSamples(10000);
    _private->rightGainRamp.setTarget(1.0, true);
    _private->rightGainRamp.setDurationInSamples(10000);
}

// Uses the ParameterAddress as a key
void DistortionDSP::setParameter(AUParameterAddress address, AUValue value, bool immediate) {
    switch (address) {
        case DistortionParameterLeftGain:
            _private->leftGainRamp.setTarget(value, immediate);
            break;
        case DistortionParameterRightGain:
            _private->rightGainRamp.setTarget(value, immediate);
            break;
        case DistortionParameterRampDuration:
            _private->leftGainRamp.setRampDuration(value, _sampleRate);
            _private->rightGainRamp.setRampDuration(value, _sampleRate);
            break;
        case DistortionParameterRampType:
            _private->leftGainRamp.setRampType(value);
            _private->rightGainRamp.setRampType(value);
            break;
    }
}

// Uses the ParameterAddress as a key
float DistortionDSP::getParameter(AUParameterAddress address) {
    switch (address) {
        case DistortionParameterLeftGain:
            return _private->leftGainRamp.getTarget();
        case DistortionParameterRightGain:
            return _private->rightGainRamp.getTarget();
        case DistortionParameterRampDuration:
            return _private->leftGainRamp.getRampDuration(_sampleRate);
    }
    return 0;
}

void DistortionDSP::process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) {
    for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
        int frameOffset = int(frameIndex + bufferOffset);
        // do ramping every 8 samples
        if ((frameOffset & 0x7) == 0) {
            _private->leftGainRamp.advanceTo(_now + frameOffset);
            _private->rightGainRamp.advanceTo(_now + frameOffset);
        }
    
        
        for (int channel = 0; channel < _nChannels; ++channel) {
            float *in  = (float *)_inBufferListPtr->mBuffers[channel].mData  + frameOffset;
            float *out = (float *)_outBufferListPtr->mBuffers[channel].mData + frameOffset;
            
            /*
            if (channel == 0) {
                *out = *in * _private->leftGainRamp.getValue();
            } else {
                *out = *in * _private->rightGainRamp.getValue();
            }
            */
            
            float limit = _private->leftGainRamp.getValue();
            
            
            float x = *in;
            if (x >= limit) {
                x = limit;
            } else if (x <= -limit) {
                x = -limit;
            }
            *out = x;
             
            
            /*
            *in *= (0.7 + limit);
            if (*in > 1) {
                *out = 1;
            } else if (*in < -1) {
                *out = -1;
            } else {
                *out = *in;
            }
             */
        }
    }
}
