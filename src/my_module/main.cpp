
// Copyright (c) 2024 maishuji. All rights reserved.
/* @author maishuji
 * This code is just a template to get you started.
 * You can delete it and start from scratch.
 */

#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <iostream>
#include <sstream>
#include <string>

#include "my_module/game_utils.h"
#include "raylib/raylib.h"
#include "raylib/raymath.h"
#include "raylib/rlgl.h"

#if defined(PLATFORM_DREAMCAST)
#include <kos.h>

KOS_INIT_FLAGS(INIT_DEFAULT);
#endif

static void log_milestone(const char *message) {
#if defined(PLATFORM_DREAMCAST)
    // Keep the active KOS dbgio device (e.g. dcload or Flycast serial).
    dbglog(DBG_NOTICE, "dreamcast-template: %s\n", message);
    dbgio_flush();
#else
    std::fprintf(stderr, "dreamcast-template: %s\n", message);
    std::fflush(stderr);
#endif
}

int main(int argc, char **argv) {

    // Check if we are running on Dreamcast and in debug mode
#if defined(PLATFORM_DREAMCAST) && defined(DEBUG)
    dbglog(DBG_ERROR, "Running on Dreamcast in debug mode.\n");
    gdb_init();
    dbglog(DBG_ERROR, "GDB initialized.\n");
    // You can manually set breakpoints in the code with gdb_breakpoint() function,
    // or use gdb commands to set breakpoints.
#endif

    log_milestone("booted");
    InitWindow(640, 480, "Block stacking puzzle game in KOS!");
    log_milestone("renderer-ready");
    Camera camera = {0};
    camera.position = (Vector3){4.0f, 4.0f, 4.0f};  // Camera position
    camera.target = (Vector3){0.0f, 0.0f, 0.0f};    // Look-at point
    camera.up = (Vector3){0.0f, 1.0f, 0.0f};        // Camera up vector
    camera.fovy = 45.0f;                            // Field of view

    float rotationAngle = 0.0f;  // Cube rotation angle

    SetTargetFPS(60);
    auto go_on = true;

    log_milestone("frame-loop-started");
    while (go_on && !WindowShouldClose()) {
        rotationAngle = GameUtils::incrementAngle(rotationAngle, 1.0f);

        // Press START or B to quit, or close window button
        if (IsKeyPressed(KEY_SPACE) ||
            IsGamepadButtonDown(0, GAMEPAD_BUTTON_RIGHT_FACE_RIGHT)) {
            std::cout << "Exiting..." << std::endl;
            go_on = false;
        }

        BeginDrawing();
        ClearBackground(RAYWHITE);
        BeginMode3D(camera);

        rlPushMatrix();
        rlRotatef(rotationAngle, 0.0f, 1.0f, 0.0f);  // Rotate around the Y-axis
        DrawCube((Vector3){0.0f, 0.0f, 0.0f}, 2.0f, 2.0f, 2.0f, RED);
        DrawCubeWires((Vector3){0.0f, 0.0f, 0.0f}, 2.0f, 2.0f, 2.0f, DARKGRAY);

        rlPopMatrix();

        EndMode3D();

        DrawText("Hello, World. Press START to break.\n", 10, 10, 20, RED);
        std::string text = GameUtils::createRotationDisplayText(rotationAngle);

        DrawText(text.c_str(), 10, 30, 20, RED);
        // DrawRectangle(165, 145, 310, 210, BLACK);
        DrawFPS(10, 50);  // Draw FPS counter

        EndDrawing();
    }

    CloseWindow();  // Clean up window resources
    log_milestone("normal-shutdown");
    return 0;
}
