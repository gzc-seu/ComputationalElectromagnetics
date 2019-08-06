clear all;
close all;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program Info                                                            %
% Simulates FDTD in one dimension                                         %
%                                                                         %
% Note: Electric field, E, undergoes a change of variables for            %
% simplification: E_prgrm = sqrt(eps_not/mu_not)E_exact                   %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Physical Constants
epsNot = 8.854187817620e-12;    % Permittivity of Free Space
muNot = 1.25663706e-6;          % Magnetic Constant
cNot = 2.99792458e8;            % Speed of light
etaNot = sqrt(muNot/epsNot);    % Characteristic impedence of free space

%% Parameters
% Define FDTD Space
dx = .001   ;                    % Cell Size (1 = 1meter)                  [USER DEFINED]
dt = dx/(cNot);                 % Time step (1 = 1sec)                     [USER DEFINED]
Sc = cNot*dt/dx;                % Courant Number (only works in Vacuum)
gridSize = 800;                 % Total number of cells                    [USER DEFINED]
maxIter = 920;                  % Maximum number of iterations + 1         [USER DEFINED]

% Initialize solution vectors
xDom = 1:gridSize;
Ex = zeros(1,gridSize);
Hy = zeros(1,gridSize-1);


%% Hard source parameters
sourcePos = 1 ;                 % Location of source                       [USER DEFINED]

% Gaussian Pulse parameters
width = 30;                     % Width of Gaussian                        [USER DEFINED]
maxT = 150;                     % Decay of Gaussian                        [USER DEFINED]

% Sine Wave Parameters
f = 8e9;                       % Frequency                               [USER DEFINED]
amp = 1;                        % Amplitude of Wave                        [USER DEFINED]
lambda =cNot/f;                 % Wavelength
omega = 2*pi*f;                 % Angular Frequency

% Ricker Wavelet Parameters
fp = 5e8;                       % Peak Frequency                           [USER DEFINED]
md = 1;                         % Temporal Delay Multiple                  [USER DEFINED]
dr = md/fp;                     % Temporal Delay


%% Parameters associated with the dielectric 
posMed = 400;                   % Position of mediunm                      [USER DEFINED]
sigma = 0 ;                     % Conductivity of dielectric               [USER DEFINED]
dielC = 20;                     % Dielectric Constant (rel. Permittivity)  [USER DEFINED]
      
epsDiel = dielC*epsNot;         % Permittivity of dielectric

factor = dt*sigma/(2*epsNot*dielC);
alpha = (1-factor)/(1+factor);
beta = 1/(dielC*(1+factor));


%% Parameters associated with Debye Material
% dEps = 3;                       % Change in rel. Permittivity due to pole  [USER DEFINED]
% epsInf = 1;                     % Rel. Permittivity at infinite freq.      [USER DEFINED]  
% tau  = .001e-6  ;               % Pole relaxation time                     [USER DEFINED]
% chiNot = dEps*(1-exp(-dt/tau));                    % Initial X, susceptibility
% xiNot = dEps*tau/dt*(1-(dt/tau+1)*exp(-dt/tau));  % Inital Zeta, Convolution term
% dXnot = chiNot*(1-exp(-dt/tau));
% dZnot = xiNot*(1-exp(-dt/tau));
% psi = Ex(posMed:end-1);
% ExStore = Ex;
% alpha = (epsInf-xiNot)/(epsInf-xiNot+chiNot);
% beta = 1/(epsInf-xiNot+chiNot);
% kappa = 1/(epsInf-xiNot+chiNot);


%% Parameters associated with Lorentz Material

% dEps = 3;                       % Change in rel. Permittivity due to pole  [USER DEFINED]
% epsInf = 1.5;                   % Rel. Permittivity at infinite freq.      [USER DEFINED]
% freqL = .5e9;                   % Undamped Resonance Frequency of med      [USER DEFINED]         
% omegaMed = 2*pi*freqL;          % Angular freq equivalent of freqL
% sigmaMed = .1*omegaMed  ;       % Conductivity of Lorentz Medium           [USER DEFINED]
% 
% % Parameters associated with lorentz medium
% alphaL = sigmaMed;
% betaL = sqrt(omegaMed^2-sigmaMed^2);
% gamma = dEps*omegaMed^2/betaL
% 
% chiNot = -j*gamma/(alphaL-j*betaL)*(1-exp((-alphaL+j*betaL)*dt));     % Initial X, susceptibility
% xiNot = (-j*gamma/dt)/(alphaL-j*betaL)^2*...
%        (((alphaL-j*betaL)*dt+1)*exp((-alphaL+j*betaL)*dt)-1)  ;     % Inital Zeta, Convolution term
%    
% dXnot = chiNot*(1-exp((-alphaL+j*betaL)*dt))
% dZnot = xiNot*(1-exp((-alphaL+j*betaL)*dt));
% 
% chiNot = real(chiNot)
% xiNot = real(xiNot)
% 
% psi = Ex(posMed:end-1);
% ExStore = Ex;
% alpha = (epsInf-xiNot)/(epsInf-xiNot+chiNot);
% beta = 1/(epsInf-xiNot+chiNot);
% kappa = 1/(epsInf-xiNot+chiNot);


%% Initialization of Detector for frequency domain

% Specify detector locations
detInitial = sourcePos+1;             % Position of initial wave detector  [USER DEFINED]
detPost = posMed + 10;                % Position of latter wave detector  [USER DEFINED]
detRef = posMed - 300;                 % Position of reflection detector

detectorInitial = zeros(1,maxIter-1);
detectorFinal = zeros(1,maxIter-1);
detectorRef = detectorFinal;


%%


%%%%%% MAIN SOLUTION LOOP %%%%%%
figure('outerposition', [710   500   1000   600])
set(1,'color',[.9 .9 .9])

for n = 1:maxIter

% Generate Gaussian Pulse
% source = exp(-.5*((maxT-n)/width)^2);

% Generate wave packet
source = exp(-.5*((maxT-n)/width)^2) * amp*sin(omega*n*dt);
    
% Generate sine hard source
% source = amp*sin(omega*n*dt);

% Generate Ricker Wavelet
% source = (1-2*(pi*fp*(n*dt-dr))^2)*exp(-(pi*fp*(n*dt-dr))^2);


%% Without dielectric
% 
% % E-field Boundary Update
% Ex(1)   = 0 ;
% Ex(end) = 0 ;
% 
% % E-field Update
% Ex(2:end-1) = Ex(2:end-1) - Cn*( Hy(2:end) - Hy(1:end-1) );
% Ex(sourcePos)  = source;
% 
% % H-field Update
% Hy          =      Hy     - Cn*( Ex(2:end) - Ex(1:end-1) ); 


%% With Dielectric
% E-field Boundary Update
Ex(1)   = 0 ;
Ex(end) = 0 ;

% E-field Update
% Before media is reached
Ex(2:posMed-1)   =       Ex(2:posMed-1)   -      Sc*( Hy(2:posMed-1) - Hy(1:posMed-2)     );
% Update after media is reached
Ex(posMed:end-1) = alpha*Ex(posMed:end-1) - beta*Sc*( Hy(posMed:end) - Hy(posMed-1:end-1) );
Ex(sourcePos)    = source;

% H-field Update
Hy               =            Hy          -      Sc*( Ex(2:end)      -  Ex(1:end-1)       ); 


%% With Debye Media
% % E-field Boundary Update
% Ex(1)   = 0 ;
% Ex(end) = 0 ;
% 
% % E-field Update
% % Before media is reached
% Ex(2:posMed-1)   = Ex(2:posMed-1) - Cn*( Hy(2:posMed-1) - Hy(1:posMed-2) );
% % Update after media is reached
% Ex(posMed:end-1) = alpha*Ex(posMed:end-1) - ...
%                    beta*Cn*( Hy(posMed:end) - Hy(posMed-1:end-1) ) + ...
%                    kappa*psi;
% Ex(sourcePos)    = source;
% 
% % Update Psi
% psi = (dXnot-dZnot)*Ex(posMed:end-1) + dZnot*ExStore(posMed:end-1) + psi*exp(-dt/tau);
% ExStore = Ex;
% 
% % H-field Update
% Hy  =  Hy - Cn*( Ex(2:end) -  Ex(1:end-1) ); 

%% With Lorentz Media
% E-field Boundary Update
% Ex(1)   = 0 ;
% Ex(end) = 0 ;
% 
% % E-field Update
% % Before media is reached
% Ex(2:posMed-1)   = Ex(2:posMed-1) - Sc*( Hy(2:posMed-1) - Hy(1:posMed-2) );
% % Update after media is reached
% Ex(posMed:end-1) = alpha*Ex(posMed:end-1) - ...
%                    beta*Sc*( Hy(posMed:end) - Hy(posMed-1:end-1) ) + ...
%                    kappa*real(psi);
% Ex(sourcePos)    = source;
% 
% % Update Psi
% psi = (dXnot-dZnot)*Ex(posMed:end-1) + dZnot*ExStore(posMed:end-1) + psi*exp((-alphaL+j*betaL)*dt);
% ExStore = Ex;
% 
% % H-field Update
% Hy  =  Hy - Sc*( Ex(2:end) -  Ex(1:end-1) ); 



%% Update detector
detectorInitial(n) = Ex(detInitial);
detectorFinal(n) = Ex(detPost);
if Sc*n > posMed
    detectorRef(n) = Ex(detRef);
else
    detectorRef(n) = 0;
end

%%
if mod(n,5) == 0;
    
% Generate plots/movie
% subplot(2,1,1)
hold on
rectangle('position',[posMed, -1.2, gridSize, 4], 'facecolor', [.8 .8 .8])
plot(xDom, Ex, 'r-')
axis([0 gridSize -1.2 1.2])
title('Gauss Pulse entering Frequency Dependent (Lorentz) Medium')
xlabel('x/4 (mm)')
ylabel('E_z')

% Display pertinent parameters
% waveFreq = num2str(f/10^6);
% wave = strcat('Peak Frequency: ', waveFreq, 'MHz');
% text(gridSize/10, 1.05, wave)
% 
% timeStep = num2str(n);
% time = strcat('Time Step: { }', timeStep);
% text(gridSize/1.5, .1, time);
% 
% timeElaps = num2str(round(n*dt*10^13)*10^-1);
% timeElapsed = strcat('Time elapsed:{ } ', timeElaps, 'pS');
% text(gridSize/1.5, .05, timeElapsed); 
% 
% dielEps = num2str(dEps);
% dielectricCons = strcat('{\Delta} {\epsilon}_r = { } ', dielEps);
% text(posMed+5, .05, dielectricCons)
% 
% dielEps = num2str(epsInf);
% dielectricCons = strcat('{\Delta} {\epsilon}_{\infty} = { } ', dielEps);
% text(posMed+5, .1, dielectricCons)

% dielCons = num2str(dielC);
% dielectricCons = strcat('Dielectric Constant {\epsilon}_r = ', dielCons);
% text(posMed+1, 1.0, dielectricCons)
% 
% conduct = num2str(sigma);
% conductivity = strcat('Conductivity {\sigma} = ', conduct);
% text(posMed+1, .8, conductivity)
% 
% subplot(2,1,2)
% hold on
% rectangle('position',[posMed, -1.2, gridSize, 4], 'facecolor', [.8 .8 .8])
% plot(xDom(1:end-1),Hy)
% axis([0 gridSize -1.2 1.2])  
% xlabel('x/4 (mm)')
% ylabel('H_y')
%  
M(n/5) = getframe(gcf);
end

if n>maxIter-2;

    figure('outerposition', [100   500   1000   500])
    
    % Plot detected waves
    subplot(2,1,1)
    observations = length(detectorInitial);
    timeDom = (0:observations-1).*dt;
    plot(timeDom, detectorInitial, timeDom, detectorFinal, timeDom, detectorRef)
    legend('Initial detector', 'Final detector', 'Reflected Wave')
    title('Detected waves in time domain')
    xlabel('t, time')
    ylabel('Amplitude')
    
    % Generate frequency spectrum
    Fs = 1/dt;
    freqDom = (0:observations/2-1)*Fs/(observations);
    fourierInit = fft(detectorInitial);
    fourierFinal = fft(detectorFinal);
    fourierRef = fft(detectorRef);
    
    magInit = (abs(fourierInit(1:observations/2))).^2;
    magFinal = (abs(fourierFinal(1:observations/2))).^2;
    magRef = (abs(fourierRef(1:observations/2))).^2;
    
    % Plot freq. spectrum
    subplot(2,1,2)
    hold on
    stem(freqDom./10^9, magInit, 'b')
    plot(freqDom./10^9, magFinal, 'g')
    plot(freqDom./10^9, magRef, 'r')
    hold off
    ylabel('Power') 
    xlabel('Frequency (GHz)')
    legend('Inital Spectrum', 'Transmitted Spectrum', 'Reflected spectrum')
    title('Frequency Spectrum')
    
    % Plot transmission graph
    figure('outerposition', [100   500   1000   500])
    trans = zeros(length(freqDom),1);
    refl = trans;
    
    for k = 1:observations/2;
        if magInit(k) > 1
             trans(k) = magFinal(k)/magInit(k);
             refl(k) = magRef(k)/magInit(k);
        end
    end
    
    trans = sqrt(trans)
    refl = sqrt(refl)
    
    plot(freqDom./10^9, trans, freqDom./10^9, refl, freqDom./10^9, trans+refl)
    ylabel('Transmitted/Reflected') 
    xlabel('Frequency (GHz)')
    legend('Transmitted', 'Reflected')
    title('Transmission/Reflection')
    
    
    return
end

hold off
clf

end
    

% movie2avi(M, 'Gauss Pulse 1D Debye Media', 'fps', 40);

