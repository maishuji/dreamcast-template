// Copyright 2025 Quentin Cartier

#include "my_module/game_utils.h"
#include <sstream>
#include <ios>
#include <cmath>

namespace GameUtils {

float normalizeAngle(float angle) {
    while (angle >= 360.0f) {
        angle -= 360.0f;
    }
    while (angle < 0.0f) {
        angle += 360.0f;
    }
    return angle;
}

float incrementAngle(float currentAngle, float increment) {
    return normalizeAngle(currentAngle + increment);
}

std::string formatFloatWithPrecision(float value, int precision) {
    std::ostringstream oss;
    oss.setf(std::ios::fixed);
    oss.precision(precision);
    oss << value;
    return oss.str();
}

std::string createRotationDisplayText(float angle) {
    return "Rotation angle: " + formatFloatWithPrecision(angle, 3);
}

float calculateFrameTime(int targetFPS) {
    if (targetFPS <= 0) {
        return 0.0f;
    }
    return 1.0f / targetFPS;
}

bool isValidFrameRate(int fps) {
    return fps > 0 && fps <= 1000;  // Reasonable bounds
}

CameraConfig createDefaultCamera() {
    return {
        4.0f,
        4.0f,
        4.0f,  // position
        0.0f,
        0.0f,
        0.0f,  // target
        0.0f,
        1.0f,
        0.0f,  // up
        45.0f  // fovy
    };
}

bool isValidCameraConfig(const CameraConfig& config) {
    // Check if FOV is reasonable
    if (config.fovy <= 0.0f || config.fovy >= 180.0f) {
        return false;
    }

    // Check if up vector is not zero
    if (std::abs(config.upX) < 0.001f && std::abs(config.upY) < 0.001f &&
        std::abs(config.upZ) < 0.001f) {
        return false;
    }

    return true;
}

}  // namespace GameUtils
