clc; clear; close all;

% Physical constants
c = 3e8;                 % Speed of light (m/s)

% Transmission line parameters
Z0 = 50;                 % Characteristic impedance (Ohms)
ZL = 100;                % Load impedance (Ohms)
er = 4;                  % Relative permittivity
l = 0.1;                 % Line length (meters)

% Frequency sweep
f = linspace(1e6,10e9,2000);   % 1 MHz to 10 GHz
vp = c / sqrt(er);       % Phase velocity
beta = 2*pi*f / vp;     % Phase constant
alpha = 0;              % Lossless line
gamma = alpha + 1i*beta;

Gamma_L = (ZL - Z0) / (ZL + Z0);
Gamma_in = Gamma_L .* exp(-2*gamma*l);
figure;
plot(f/1e9, abs(Gamma_in), 'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('|Reflection Coefficient|');
title('Reflection Coefficient vs Frequency');
grid on;


VSWR = (1 + abs(Gamma_in)) ./ (1 - abs(Gamma_in));
RL = -20*log10(abs(Gamma_in));
figure;
plot(f/1e9, VSWR, 'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('VSWR');
title('VSWR vs Frequency');
grid on;

figure;
plot(f/1e9, RL, 'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('Return Loss (dB)');
title('Return Loss vs Frequency');
grid on;
Zin = Z0 .* (1 + Gamma_in) ./ (1 - Gamma_in);
figure;
plot(f/1e9, real(Zin), 'LineWidth',1.5); hold on;
plot(f/1e9, imag(Zin), '--', 'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('Impedance (Ohms)');
legend('Real(Zin)','Imag(Zin)');
title('Input Impedance vs Frequency');
grid on;

S11 = Gamma_in;
S21 = exp(-gamma*l);
figure;
plot(f/1e9, 20*log10(abs(S11)), 'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('|S11| (dB)');
title('S11 vs Frequency');
grid on;

figure;
plot(f/1e9, 20*log10(abs(S21)), 'LineWidth',1.5);
xlabel('Frequency (GHz)');
ylabel('|S21| (dB)');
title('S21 vs Frequency');
grid on;

ZL = Z0;
Gamma_f = Gamma_in;
Gamma_t = ifft(Gamma_f);

t = (0:length(Gamma_t)-1) / max(f);
figure;
plot(t*1e9, abs(Gamma_t), 'LineWidth',1.5);
xlabel('Time (ns)');
ylabel('Reflection Magnitude');
title('Time-Domain Reflection (TDR-like)');
grid on;

figure;
smithplot(Gamma_in);
title('Smith Chart Representation');