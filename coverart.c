// Name: Zi Chen Hu
// McGill ID: 260931572
// Final Project: an OpenGL program that draws a brick breaker game scene.

#define GL_GLEXT_PROTOTYPES
#include "GL/glut.h"

const char *vertexShaderSource ="#version 330 core\n"
    "layout (location = 0) in vec3 aPos;\n"
    "layout (location = 1) in vec3 aColor;\n"
    "out vec3 ourColor;\n"
    "void main()\n"
    "{\n"
    "   gl_Position = vec4(aPos, 1.0);\n"
    "   ourColor = aColor;\n"
    "}\0";

const char *fragmentShaderSource = "#version 330 core\n"
    "out vec4 FragColor;\n"
    "in vec3 ourColor;\n"
    "void main()\n"
    "{\n"
    "   FragColor = vec4(ourColor, 1.0f);\n"
    "}\n\0";

float brick_length = 0.09;
float brick_width = 0.063;

float brick_array[24];
float brick_color[3];

void createBrickArray(float brick_array[], float x_coord, float y_coord, float brick_color[])
{
    brick_array[3] = brick_color[0];
    brick_array[4] = brick_color[1];
    brick_array[5] = brick_color[2];
    brick_array[9] = brick_color[0];
    brick_array[10] = brick_color[1];
    brick_array[11] = brick_color[2];
    brick_array[15] = brick_color[0];
    brick_array[16] = brick_color[1];
    brick_array[17] = brick_color[2];
    brick_array[21] = brick_color[0];
    brick_array[22] = brick_color[1];
    brick_array[23] = brick_color[2];

    brick_array[0] = x_coord;
    brick_array[18] = x_coord;
    brick_array[6] = x_coord + brick_length;
    brick_array[12] = x_coord + brick_length;

    brick_array[1] = y_coord;
    brick_array[7] = y_coord;
    brick_array[13] = y_coord - brick_width;
    brick_array[19] = y_coord - brick_width;
    
    brick_array[2] = 0.0f;
    brick_array[8] = 0.0f;
    brick_array[14] = 0.0f;
    brick_array[20] = 0.0f;
}

// uh I couldn't figure out how to do it so I hardcoded on my loop iteration :D
void updateBrickColor(float brick_color[], int row_number)
{
    float colors_to_use[3];
    if(row_number == 0)
    {
        brick_color[0] = 1.000;
        brick_color[1] = 0.000;
        brick_color[2] = 0.000;
    }
    else if(row_number == 1)
    {
        brick_color[0] = 0.000;
        brick_color[1] = 0.000;
        brick_color[2] = 0.921;
    }
    else if(row_number == 2)
    {
        brick_color[0] = 0.596;
        brick_color[1] = 0.975;
        brick_color[2] = 0.596;
    }
    else if(row_number == 3)
    {
        brick_color[0] = 1.000;
        brick_color[1] = 0.714;
        brick_color[2] = 0.757;
    }
    else if(row_number == 4)
    {
        brick_color[0] = 0.690;
        brick_color[1] = 0.769;
        brick_color[2] = 0.871;
    }
    else if(row_number == 5)
    {
        brick_color[0] = 0.000;
        brick_color[1] = 0.502;
        brick_color[2] = 0.000;
    }
}

void brickBreaker()
{
    // build and compile our shader program
    // ------------------------------------
    // vertex shader
    unsigned int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);
    // fragment shader
    unsigned int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);
    // link shaders
    unsigned int shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    unsigned int indices[] = {
        0, 1, 2,
        0, 2, 3
    };

    float brick_array[24];
    float brick_color[3];

    float bricksBackground[] = {
        // positions               // colors
        // x         y       z        R        G        B
        -0.98f,    0.60f,   0.0f,   0.64f,   0.64f,   0.64f,
         0.98f,    0.60f,   0.0f,   0.64f,   0.64f,   0.64f,
         0.98f,    0.12f,   0.0f,   0.64f,   0.64f,   0.64f,
        -0.98f,    0.12f,   0.0f,   0.64f,   0.64f,   0.64f
    };

    float leftWall[] = {
        // positions               // colors
        // x         y       z        R        G        B
        -1.00f,    0.84f,   0.0f,   0.32f,   0.32f,   0.32f,
        -0.90f,    0.84f,   0.0f,   0.32f,   0.32f,   0.32f,
        -0.90f,   -0.84f,   0.0f,   0.32f,   0.32f,   0.32f,
        -1.00f,   -0.84f,   0.0f,   0.32f,   0.32f,   0.32f
    };

    float rightWall[] = {
        // positions               // colors
        // x         y       z        R        G        B
         0.90f,    0.84f,   0.0f,   0.32f,   0.32f,   0.32f,
         1.00f,    0.84f,   0.0f,   0.32f,   0.32f,   0.32f,
         1.00f,   -0.84f,   0.0f,   0.32f,   0.32f,   0.32f,
         0.90f,   -0.84f,   0.0f,   0.32f,   0.32f,   0.32f
    };

    float topWall[] = {
        // positions               // colors
        // x         y       z        R        G        B
        -1.00f,    0.84f,   0.0f,   0.28f,   0.28f,   0.28f,
         1.00f,    0.84f,   0.0f,   0.28f,   0.28f,   0.28f,
         1.00f,    0.68f,   0.0f,   0.28f,   0.28f,   0.28f,
        -1.00f,    0.68f,   0.0f,   0.28f,   0.28f,   0.28f
    };

    float leftBottom[] = {
        // positions               // colors
        // x         y       z        R        G        B
        -1.00f,   -0.88f,   0.0f,   0.32f,   0.32f,   0.32f,
        -0.90f,   -0.88f,   0.0f,   0.32f,   0.32f,   0.32f,
        -0.90f,   -1.00f,   0.0f,   0.32f,   0.32f,   0.32f,
        -1.00f,   -1.00f,   0.0f,   0.32f,   0.32f,   0.32f
    };

    float rightBottom[] = {
        // positions               // colors
        // x         y       z        R        G        B
         0.90f,   -0.88f,   0.0f,   0.32f,   0.32f,   0.32f,
         1.00f,   -0.88f,   0.0f,   0.32f,   0.32f,   0.32f,
         1.00f,   -1.00f,   0.0f,   0.32f,   0.32f,   0.32f,
         0.90f,   -1.00f,   0.0f,   0.32f,   0.32f,   0.32f
    };

    float paddle[] = {
        // positions               // colors
        // x         y       z        R        G        B
        -0.10f,   -0.84f,   0.0f,   0.50f,   1.00f,   0.00f,
         0.10f,   -0.84f,   0.0f,   0.50f,   1.00f,   0.00f,
         0.10f,   -0.88f,   0.0f,   0.50f,   1.00f,   0.00f,
        -0.10f,   -0.88f,   0.0f,   0.50f,   1.00f,   0.00f,
    };

    float ball[] = {
        // positions               // colors
        // x         y       z        R        G        B
        -0.005f,   -0.72f,   0.0f,   1.00f,   1.00f,   1.00f,
         0.000f,   -0.72f,   0.0f,   1.00f,   1.00f,   1.00f,
         0.000f,   -0.73f,   0.0f,   1.00f,   1.00f,   1.00f,
        -0.005f,   -0.73f,   0.0f,   1.00f,   1.00f,   1.00f,
    };

    int size = 116;
    unsigned int VBOs[size], VAOs[size], EBO;
    glGenVertexArrays(size, VAOs);
    glGenBuffers(size, VBOs);
    glGenBuffers(1, &EBO);

    // Create bricks contour/background
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[0]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(bricksBackground), bricksBackground, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create left wall
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[1]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(leftWall), leftWall, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create right wall
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[2]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rightWall), rightWall, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create top wall
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[3]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[3]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(topWall), topWall, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create left bottom
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[4]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[4]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(leftBottom), leftBottom, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create right bottom
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[5]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[5]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rightBottom), rightBottom, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create paddle
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[6]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[6]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(paddle), paddle, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    // Create ball
    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    glBindVertexArray(VAOs[7]);

    glBindBuffer(GL_ARRAY_BUFFER, VBOs[7]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(ball), ball, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);

    float starting_y_cood = 0.59f;
    int current_brick = 8;
    // Create bricks
    for(int i = 0; i < 6; i++)
    {
        // Update row's bricks' color
        updateBrickColor(brick_color, i);

        // For one row
        float starting_x_cood = -0.895f;
        for(int i = 0; i < 18; i++)
        {
            // Update brick array
            createBrickArray(brick_array, starting_x_cood, starting_y_cood, brick_color);

            // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
            glBindVertexArray(VAOs[current_brick]);

            glBindBuffer(GL_ARRAY_BUFFER, VBOs[current_brick]);
            glBufferData(GL_ARRAY_BUFFER, sizeof(brick_array), brick_array, GL_STATIC_DRAW);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

            // position attribute
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
            glEnableVertexAttribArray(0);
            // color attribute
            glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
            glEnableVertexAttribArray(1);

            // Go to next brick
            starting_x_cood = starting_x_cood + brick_length + 0.01;
            current_brick = current_brick + 1;
        }
        // Update coordinates
        starting_x_cood = -0.89f;
        starting_y_cood = starting_y_cood - brick_width - 0.015;
    }

    // as we only have a single shader, we could also just activate our shader once beforehand if we want to 
    glUseProgram(shaderProgram);

    // No need to render the background since we want it black anyway

    // render the bricks background
    glBindVertexArray(VAOs[0]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the left wall
    glBindVertexArray(VAOs[1]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the right wall
    glBindVertexArray(VAOs[2]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the top wall
    glBindVertexArray(VAOs[3]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArray(VAOs[1]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the left bottom
    glBindVertexArray(VAOs[4]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the right bottom
    glBindVertexArray(VAOs[5]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the paddle
    glBindVertexArray(VAOs[6]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // render the ball
    glBindVertexArray(VAOs[7]);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    for(int i = 8; i < size; i++)
    {
        // render each brick
        glBindVertexArray(VAOs[i]);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    }

    glutSwapBuffers();
}

int main(int argc, char **argv)
{
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE);
    glutInitWindowSize(640, 400);
    glutInitWindowPosition(100, 100);
    glutCreateWindow("Brick Breaker - 260931572");
    glutDisplayFunc(brickBreaker);
    glutMainLoop();
    return 0;
}
