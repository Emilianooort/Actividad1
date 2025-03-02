clear all
close all
clc

% Declaración de variables simbólicas
syms theta1(t) theta2(t) L1 L2 t

% Configuración del robot (0: rotacional, 1: prismático)
Robot_Type = [0 0];

% Vector de coordenadas articulares
Joint_Coordinates = [theta1; theta2];
disp('Coordenadas articulares');
pretty(Joint_Coordinates);

% Vector de velocidades articulares
Joint_Velocities = diff(Joint_Coordinates, t);
disp('Velocidades articulares');
pretty(Joint_Velocities);

% Número de grados de libertad del robot
DOF = size(Robot_Type, 2);

% Posiciones de las juntas
Positions(:,:,1) = [L1*cos(theta1); L1*sin(theta1); 0];
Positions(:,:,2) = Positions(:,:,1) + [L2*cos(theta1 + theta2); L2*sin(theta1 + theta2); 0];

% Matrices de rotación
Rotation_Matrices(:,:,1) = [cos(theta1) -sin(theta1) 0;
                             sin(theta1)  cos(theta1) 0;
                             0         0        1];
Rotation_Matrices(:,:,2) = Rotation_Matrices(:,:,1) * [cos(theta2) -sin(theta2) 0;
                                                       sin(theta2)  cos(theta2) 0;
                                                       0         0        1];

% Vector de ceros
Zero_Vector = zeros(1, 3);

% Inicialización de matrices de transformación homogénea
for i = 1:DOF
    Homogeneous_Matrix(:,:,i) = simplify([Rotation_Matrices(:,:,i) Positions(:,:,i); Zero_Vector 1]);
    try
        Transformation_Matrix(:,:,i) = Transformation_Matrix(:,:,i-1) * Homogeneous_Matrix(:,:,i);
    catch
        Transformation_Matrix(:,:,i) = Homogeneous_Matrix(:,:,i);
    end
    End_Effector_Position(:,:,i) = Transformation_Matrix(1:3,4,i);
    End_Effector_Rotation(:,:,i) = Transformation_Matrix(1:3,1:3,i);
end

% Cálculo del Jacobiano
Linear_Jacobian = sym(zeros(3, DOF));
Angular_Jacobian = sym(zeros(3, DOF));

for k = 1:DOF
    if Robot_Type(k) == 0
        try
            Linear_Jacobian(:,k) = cross(End_Effector_Rotation(:,3,k-1), End_Effector_Position(:,:,DOF) - End_Effector_Position(:,:,k-1));
            Angular_Jacobian(:,k) = End_Effector_Rotation(:,3,k-1);
        catch
            Linear_Jacobian(:,k) = cross([0;0;1], End_Effector_Position(:,:,DOF));
            Angular_Jacobian(:,k) = [0;0;1];
        end
    else
        try
            Linear_Jacobian(:,k) = End_Effector_Rotation(:,3,k-1);
        catch
            Linear_Jacobian(:,k) = [0;0;1];
        end
        Angular_Jacobian(:,k) = [0;0;0];
    end
end

% Cálculo de velocidades
Linear_Velocity = simplify(Linear_Jacobian * Joint_Velocities);
Angular_Velocity = simplify(Angular_Jacobian * Joint_Velocities);

disp('Velocidad lineal obtenida mediante el Jacobiano:');
pretty(Linear_Velocity);
disp('Velocidad angular obtenida mediante el Jacobiano:');
pretty(Angular_Velocity);