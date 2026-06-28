%% =========================================================
%  RF Signal Integrity Analyzer
%  Transmission Line Analysis: Reflections, Impedance Mismatch,
%  Power Loss, VSWR, Return Loss & Insertion Loss
%% =========================================================
clc; clear; close all;

fprintf('============================================================\n');
fprintf('       RF Signal Integrity Analyzer - MATLAB Edition        \n');
fprintf('============================================================\n\n');

%% ---- 1. SYSTEM PARAMETERS ----
Z0       = 50;                          % Characteristic impedance (Ohm)
f_start  = 1e6;                         % Start frequency: 1 MHz
f_stop   = 3e9;                         % Stop frequency:  3 GHz
N_f      = 1000;                        % Number of frequency points
freq     = linspace(f_start, f_stop, N_f);
omega    = 2 * pi * freq;

% Transmission line physical parameters
line_length  = 0.5;                     % meters
vp           = 2e8;                     % Phase velocity (m/s)  ~0.67c (typical coax)
alpha_dB_pm  = 0.1;                     % Attenuation: dB per meter (at 1 GHz ref)

% Load conditions to compare
Z_loads = struct();
Z_loads(1).name  = 'Matched (50\Omega)';  Z_loads(1).val = 50;
Z_loads(2).name  = 'Open Circuit';         Z_loads(2).val = inf;
Z_loads(3).name  = 'Short Circuit';        Z_loads(3).val = 0;
Z_loads(4).name  = 'Capacitive (25-j30)';  Z_loads(4).val = 25 - 1j*30;
Z_loads(5).name  = 'Inductive (75+j40)';   Z_loads(5).val = 75 + 1j*40;

colors = lines(length(Z_loads));

%% ---- 2. HELPER FUNCTIONS (nested) ----
% Reflection coefficient  Gamma = (ZL - Z0)/(ZL + Z0)
calc_gamma = @(ZL, Z0) (ZL - Z0) ./ (ZL + Z0);

% VSWR from |Gamma|
calc_vswr  = @(g_mag) (1 + g_mag) ./ (1 - g_mag);

% Return Loss (dB)
calc_RL    = @(g_mag) -20 * log10(g_mag);

% Insertion Loss (dB) - power delivered to load
calc_IL    = @(g_mag) -10 * log10(1 - g_mag.^2);

% Propagation constant  gamma = alpha + j*beta
%  alpha scales with sqrt(f) (skin effect) for simplicity
calc_gamma_prop = @(f) ...
    (alpha_dB_pm / (20*log10(exp(1)))) * sqrt(f/1e9) + ...
    1j * (2*pi*f / vp);

%% ---- 3. COMPUTE METRICS FOR EACH LOAD ----
fprintf('%-28s  |Gamma|    VSWR     RL(dB)   IL(dB)\n', 'Load Condition');
fprintf('%s\n', repmat('-', 1, 70));

results = struct();
for k = 1:length(Z_loads)
    ZL = Z_loads(k).val;

    % Propagation constant vs frequency
    gp   = calc_gamma_prop(freq);          % complex propagation constant
    egl  = exp(-gp * line_length);         % forward wave attenuation
    e2gl = exp(-2 * gp * line_length);     % round-trip

    % Load reflection coefficient (at load terminal)
    if isinf(ZL)
        Gamma_L = ones(size(freq));        % open circuit
    else
        Gamma_L = calc_gamma(ZL, Z0) * ones(size(freq));
    end

    % Input reflection coefficient (looking into line)
    Gamma_in = Gamma_L .* e2gl;

    Gamma_mag = abs(Gamma_in);
    Gamma_mag = min(Gamma_mag, 0.9999);    % clamp for VSWR computation

    VSWR = calc_vswr(Gamma_mag);
    RL   = calc_RL(Gamma_mag);
    IL   = calc_IL(Gamma_mag);

    % At center frequency for table
    idx_c = round(N_f/2);
    fprintf('%-28s  %6.4f  %8.3f  %8.3f  %8.3f\n', ...
        strrep(Z_loads(k).name, '\Omega', 'Ohm'), ...
        Gamma_mag(idx_c), VSWR(idx_c), RL(idx_c), IL(idx_c));

    results(k).Gamma_mag = Gamma_mag;
    results(k).VSWR      = VSWR;
    results(k).RL        = RL;
    results(k).IL        = IL;
    results(k).name      = Z_loads(k).name;
end
fprintf('\n(Values shown at f = %.2f GHz, line length = %.2f m)\n\n', ...
    freq(round(N_f/2))/1e9, line_length);

%% ---- 4. FREQUENCY SWEEP PLOTS ----
figure('Name','RF Signal Integrity – Frequency Sweep', ...
    'Position',[50 50 1400 900], 'Color','w');

freq_GHz = freq / 1e9;

% --- 4a. Reflection Coefficient vs Frequency ---
subplot(2,3,1); hold on; grid on;
for k = 1:length(Z_loads)
    plot(freq_GHz, results(k).Gamma_mag, 'LineWidth', 1.6, 'Color', colors(k,:));
end
xlabel('Frequency (GHz)'); ylabel('|\Gamma|');
title('Reflection Coefficient vs Frequency');
legend({Z_loads.name}, 'Location','best','FontSize',7);
ylim([0 1.05]);

% --- 4b. VSWR vs Frequency ---
subplot(2,3,2); hold on; grid on;
for k = 1:length(Z_loads)
    vswr_plot = min(results(k).VSWR, 50);   % cap display at 50
    plot(freq_GHz, vswr_plot, 'LineWidth', 1.6, 'Color', colors(k,:));
end
yline(2, 'r--', 'VSWR=2 threshold', 'LabelHorizontalAlignment','left');
xlabel('Frequency (GHz)'); ylabel('VSWR');
title('VSWR vs Frequency');
legend({Z_loads.name}, 'Location','best','FontSize',7);
ylim([1 15]);

% --- 4c. Return Loss vs Frequency ---
subplot(2,3,3); hold on; grid on;
for k = 1:length(Z_loads)
    rl_plot = min(results(k).RL, 60);
    plot(freq_GHz, rl_plot, 'LineWidth', 1.6, 'Color', colors(k,:));
end
yline(10, 'r--', 'RL=10 dB threshold', 'LabelHorizontalAlignment','left');
xlabel('Frequency (GHz)'); ylabel('Return Loss (dB)');
title('Return Loss vs Frequency');
legend({Z_loads.name}, 'Location','best','FontSize',7);

% --- 4d. Insertion Loss vs Frequency ---
subplot(2,3,4); hold on; grid on;
for k = 1:length(Z_loads)
    plot(freq_GHz, results(k).IL, 'LineWidth', 1.6, 'Color', colors(k,:));
end
xlabel('Frequency (GHz)'); ylabel('Insertion Loss (dB)');
title('Insertion Loss vs Frequency');
legend({Z_loads.name}, 'Location','best','FontSize',7);

%% ---- 5. LINE LENGTH EFFECT ----
lengths    = linspace(0.01, 2.0, 300);   % 1 cm to 2 m
f_test     = [500e6, 1e9, 2e9];          % 500 MHz, 1 GHz, 2 GHz
ZL_test    = 75 + 1j*40;                 % inductive mismatch

subplot(2,3,5); hold on; grid on;
clrs_len = {'b','r','g'};
for fi = 1:length(f_test)
    gp_test = calc_gamma_prop(f_test(fi));
    Gamma_L_test = calc_gamma(ZL_test, Z0);
    Gamma_in_len = Gamma_L_test * exp(-2 * gp_test * lengths);
    RL_len = -20 * log10(abs(Gamma_in_len));
    RL_len = min(RL_len, 60);
    plot(lengths, RL_len, 'LineWidth', 1.8, 'Color', clrs_len{fi}, ...
        'DisplayName', sprintf('f = %.0f MHz', f_test(fi)/1e6));
end
xlabel('Line Length (m)'); ylabel('Return Loss (dB)');
title('RL vs Line Length  [Z_L = 75+j40 \Omega]');
legend('Location','best','FontSize',8);

%% ---- 6. SMITH CHART (Gamma plane) ----
subplot(2,3,6); hold on; axis equal; grid on;
theta = linspace(0, 2*pi, 360);

% Draw |Gamma|=const circles
for r = [0.2 0.4 0.6 0.8 1.0]
    plot(r*cos(theta), r*sin(theta), 'Color',[0.7 0.7 0.7], 'LineWidth', 0.8);
end
plot(cos(theta), sin(theta), 'k', 'LineWidth', 1.5);   % unit circle

% Plot Gamma at mid-frequency for each load
idx_sm = round(N_f/2);
for k = 1:length(Z_loads)
    ZL = Z_loads(k).val;
    if isinf(ZL)
        G = 1;
    else
        G = calc_gamma(ZL, Z0);
    end
    % Apply line transformation (electrically short approx at ~1.5 GHz)
    gp_mid = calc_gamma_prop(freq(idx_sm));
    G_in   = G * exp(-2 * gp_mid * line_length);
    scatter(real(G_in), imag(G_in), 80, colors(k,:), 'filled', ...
        'DisplayName', Z_loads(k).name);
end
xlabel('Re(\Gamma)'); ylabel('Im(\Gamma)');
title('Smith Chart – Input \Gamma at 1.5 GHz');
legend('Location','southoutside','FontSize',6,'NumColumns',2);
xlim([-1.2 1.2]); ylim([-1.2 1.2]);

sgtitle('RF Signal Integrity Analyzer – Transmission Line Analysis', ...
    'FontSize', 14, 'FontWeight', 'bold');

%% ---- 7. THEORETICAL VALIDATION ----
fprintf('=== Theoretical Validation ===\n');
fprintf('Matched load (ZL=Z0=50): Gamma should be 0\n');
G_match = calc_gamma(50, 50);
fprintf('  Computed |Gamma| = %.6f  (expected 0.000000) --> %s\n\n', ...
    abs(G_match), pass_fail(abs(G_match) < 1e-10));

fprintf('Open circuit (ZL=inf): Gamma should be +1\n');
G_open = 1;   % analytic limit
fprintf('  |Gamma| = %.6f  (expected 1.000000) --> %s\n\n', abs(G_open), pass_fail(1));

fprintf('Short circuit (ZL=0): Gamma should be -1\n');
G_short = calc_gamma(0, 50);
fprintf('  Gamma = %.4f  (expected -1.0000) --> %s\n\n', ...
    G_short, pass_fail(abs(G_short + 1) < 1e-10));

fprintf('VSWR for |Gamma|=0.5 should be 3.0\n');
vswr_check = calc_vswr(0.5);
fprintf('  VSWR = %.4f  (expected 3.0000) --> %s\n\n', ...
    vswr_check, pass_fail(abs(vswr_check - 3.0) < 1e-10));

fprintf('Return Loss for |Gamma|=0.1 should be 20.0 dB\n');
rl_check = calc_RL(0.1);
fprintf('  RL = %.4f dB  (expected 20.0000 dB) --> %s\n\n', ...
    rl_check, pass_fail(abs(rl_check - 20) < 1e-6));

fprintf('============================================================\n');
fprintf('Analysis Complete. Figures generated.\n');
fprintf('============================================================\n');

%% ---- LOCAL FUNCTION ----
function s = pass_fail(cond)
    if cond, s = 'PASS ✓'; else, s = 'FAIL ✗'; end
end
