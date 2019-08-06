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
dx = 8.5e-9   ;                 % Cell Size (1 = 1meter)                   [USER DEFINED]
dt = .5*dx/(cNot);              % Time step (1 = 1sec)                     [USER DEFINED]
Sc = cNot*dt/dx;                % Courant Number (only works in Vacuum)
gridSize = 3000;                % Total number of cells                    [USER DEFINED]
maxIter = 5600;                 % Maximum number of iterations + 1         [USER DEFINED]

% Initialize solution vectors
xDom = 1:gridSize;
Ex = zeros(1,gridSize);
Hy = zeros(1,gridSize-1);
ExStoreEnd = Ex(end-1);
ExStoreStart = Ex(2);

%% Hard source parameters
sourcePos = 2 ;                 % Location of source                       [USER DEFINED]

% Gaussian Pulse parameters
width = 100;                     % Width of Gaussian                        [USER DEFINED]
maxT = 400;                     % Decay of Gaussian                        [USER DEFINED]

% Sine Wave Parameters
f = 1.5e9;                       % Frequency                                 [USER DEFINED]
amp = 1;                        % Amplitude of Wave                        [USER DEFINED]
lambda =cNot/f;                 % Wavelength
omega = 2*pi*f;                 % Angular Frequency

% Ricker Wavelet Parameters
fp = 5e8;                       % Peak Frequency                           [USER DEFINED]
md = 1;                         % Temporal Delay Multiple                  [USER DEFINED]
dr = md/fp;                     % Temporal Delay


%% Parameters associated with the dielectric 
posMed = 1500;                   % Position of mediunm                      [USER DEFINED]
sigma = 0 ;                     % Conductivity of dielectric               [USER DEFINED]
dielC = 4;                      % Dielectric Constant (rel. Permittivity)  [USER DEFINED]
      
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

dEps = 3;                       % Change in rel. Permittivity due to pole  [USER DEFINED]
epsInf = 1.5;                   % Rel. Permittivity at infinite freq.      [USER DEFINED]
freqL = 100e12;                   % Undamped Resonance Frequency of med      [USER DEFINED]         
omegaMed = 2*pi*freqL;          % Angular freq equivalent of freqL
sigmaMed = .1*omegaMed  ;       % Conductivity of Lorentz Medium           [USER DEFINED]

% Parameters associated with lorentz medium
alphaL = sigmaMed;
betaL = sqrt(omegaMed^2-sigmaMed^2);
gamma = dEps*omegaMed^2/betaL

chiNot = -j*gamma/(alphaL-j*betaL)*(1-exp((-alphaL+j*betaL)*dt));     % Initial X, susceptibility
xiNot = (-j*gamma/dt)/(alphaL-j*betaL)^2*...
       (((alphaL-j*betaL)*dt+1)*exp((-alphaL+j*betaL)*dt)-1)  ;     % Inital Zeta, Convolution term
   
dXnot = chiNot*(1-exp((-alphaL+j*betaL)*dt))
dZnot = xiNot*(1-exp((-alphaL+j*betaL)*dt));

chiNot = real(chiNot)
xiNot = real(xiNot)

psi = Ex(posMed:end-1);
ExStore = Ex;
alpha = (epsInf-xiNot)/(epsInf-xiNot+chiNot);
beta = 1/(epsInf-xiNot+chiNot);
kappa = 1/(epsInf-xiNot+chiNot);


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
figure('outerposition', [210   200   500   400])
set(1,'color',[.9 .9 .9])

for n = 1:maxIter

% Generate Gaussian Pulse
% if n < maxT*2;
source = exp(-.5*((maxT-n)/width)^2);
% end

% Generate wave packet
% source = exp(-.5*((maxT-n)/width)^2) * amp*sin(omega*n*dt);
    
% Generate sine hard source
% source = amp*sin(omega*n*dt);

% Generate Ricker Wavelet
% source = (1-2*(pi*fp*(n*dt-dr))^2)*exp(-(pi*fp*(n*dt-dr))^2);


%% Without dielectric

% 
% % E-field Update
% Ex(2:end-1) = Ex(2:end-1) - Sc*( Hy(2:end) - Hy(1:end-1) );
% Ex(sourcePos)  = source;
% 
% % MUR boundary
% Ex(end) = ExStoreEnd + ((cNot*dt-dx)/(cNot*dt+dx))*(Ex(end-1)-Ex(end));
% Ex(1) = ExStoreStart + ((cNot*dt-dx)/(cNot*dt+dx))*(Ex(2)-Ex(1));
% 
% % Store Ex
% ExStoreEnd = Ex(end-1);
% ExStoreStart = Ex(2);
% 
% % H-field Update
% Hy          =      Hy     - Sc*( Ex(2:end) - Ex(1:end-1) ); 

%% With Dielectric

% % E-field Boundary Update
% Ex(1)   = 0 ;
% Ex(end) = 0 ;
% 
% % E-field Update
% % Before media is reached
% Ex(2:posMed-1)   =       Ex(2:posMed-1)   -      Sc*( Hy(2:posMed-1) - Hy(1:posMed-2)     );
% % Update after media is reached
% Ex(posMed:end-1) = alpha*Ex(posMed:end-1) - beta*Sc*( Hy(posMed:end) - Hy(posMed-1:end-1) );
% Ex(sourcePos)    = source;
% 
% % H-field Update
% Hy               =            Hy          -      Sc*( Ex(2:end)      -  Ex(1:end-1)       ); 


%% With Debye Media
% % E-field Boundary Update
% Ex(1)   = 0 ;
% Ex(end) = 0 ;
% 
% % E-field Update
% % Before media is reached
% Ex(2:posMed-1)   = Ex(2:posMed-1) - Sc*( Hy(2:posMed-1) - Hy(1:posMed-2) );
% % Update after media is reached
% Ex(posMed:end-1) = alpha*Ex(posMed:end-1) - ...
%                    beta*Sc*( Hy(posMed:end) - Hy(posMed-1:end-1) ) + ...
%                    kappa*psi;
% Ex(sourcePos)    = source;
% 
% % Update Psi
% psi = (dXnot-dZnot)*Ex(posMed:end-1) + dZnot*ExStore(posMed:end-1) + psi*exp(-dt/tau);
% ExStore = Ex;
% 
% 
% % H-field Update
% Hy  =  Hy - Sc*( Ex(2:end) -  Ex(1:end-1) ); 


%% With Lorentz Media
% E-field Boundary Update
Ex(1)   = 0 ;
Ex(end) = 0 ;

% E-field Update
% Before media is reached
Ex(2:posMed-1)   = Ex(2:posMed-1) - Sc*( Hy(2:posMed-1) - Hy(1:posMed-2) );
% Update after media is reached
Ex(posMed:end-1) = alpha*Ex(posMed:end-1) - ...
                   beta*Sc*( Hy(posMed:end) - Hy(posMed-1:end-1) ) + ...
                   kappa*real(psi);
Ex(sourcePos)    = source;

% Update Psi
psi = (dXnot-dZnot)*Ex(posMed:end-1) + dZnot*ExStore(posMed:end-1) + psi*exp((-alphaL+j*betaL)*dt);
ExStore = Ex;

% H-field Update
Hy  =  Hy - Sc*( Ex(2:end) -  Ex(1:end-1) ); 



%% Update detector
if n < 800
    detectorInitial(n) = Ex(detInitial);
end

if n < 2100
    detectorFinal(n) = Ex(detPost);
end

if n > 1600
    detectorRef(n) = Ex(detRef);
end

%%
movieStart = 2800;
if mod(n-movieStart,30) == 0 && n > movieStart;
    
% Generate plots/movie
% subplot(2,1,1)
hold on
disConv = dx*10^6;
rectangle('position',[posMed*disConv, -1.2, max(xDom*disConv), 4], 'facecolor', [.8 .8 .8])
plot(xDom*disConv, Ex, 'r-')
axis([0 max(xDom*disConv) -.6 1])
title('Gaussian entering Lorentz Medium')
xlabel('{\mu}m')
ylabel('E_z')

plot(detInitial*disConv, 0, 'ro', detPost*disConv, 0, 'g*' , detRef*disConv, 0, 'b+')


% Display pertinent parameters
% waveFreq = num2str(f/10^6);
% wave = strcat('Peak Frequency: ', waveFreq, 'MHz');
% text(gridSize/10, 1.05, wave)
% 
timeStep = num2str(n);
time = strcat('Time Step: { }', timeStep);
text(gridSize/1.5*disConv, .5, time);

courant = num2str(Sc);
infoC = strcat('Courant number {\nu}= ', courant);
text(gridSize/1.5*disConv, .3, infoC); 

timeElaps = num2str(round(n*dt*10^16)*10^-1);
timeElapsed = strcat('Time elapsed:{ } ', timeElaps, 'fs');
text(gridSize/1.5*disConv, .15, timeElapsed); 

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
M((n-movieStart)/30) = getframe(gcf);
end
% %%
% if n>maxIter-2;
%     figure('outerposition', [100   500   1000   500])
%     
%     % Plot detected waves
%     subplot(2,1,1)
%     observations = length(detectorInitial);
%     timeDom = (0:observations-1).*dt;
%     plot(timeDom, detectorInitial, timeDom, detectorFinal, timeDom, detectorRef)
%     legend('Initial wavelet', 'Transmitted wavelet', 'Reflected wavelet')
%     title('Detected waves in time domain')
%     xlabel('t, time')
%     ylabel('Amplitude')
%     
%     % Generate frequency spectrum
%     Fs = 1/dt;
%     freqDom = (0:observations/2-1)*Fs/(observations);
%     fourierInit = fft(detectorInitial);
%     fourierFinal = fft(detectorFinal);
%     fourierRef = fft(detectorRef);
%     
%     magInit = (abs(fourierInit(1:observations/2))).^2;
%     magFinal = (abs(fourierFinal(1:observations/2))).^2;
%     magRef = (abs(fourierRef(1:observations/2))).^2;
%     
%     [A indexMax] = max(magInit);
%     primaryFreq = freqDom(indexMax);
%     wavelengthPrimary = cNot/primaryFreq;
%     pointsPerWave = wavelengthPrimary/dx;
%     
%     % Plot freq. spectrum
%     subplot(2,1,2)
%     hold on
%     plot(freqDom./10^12, magInit, 'b')
%     plot(freqDom./10^12, magFinal, 'g')
%     plot(freqDom./10^12, magRef, 'r')
%     hold off
%     ylabel('Power') 
%     xlabel('Frequency (THz)')
%     legend('Inital Spectrum', 'Transmitted Spectrum', 'Reflected spectrum')
%     title('Frequency Spectrum')
%     axis([100 600 0 1.2*max(magInit)])
%     
%     % Plot transmission graph
%     figure('outerposition', [100   500   1000   500])
%     trans = zeros(length(freqDom),1);
%     refl = trans;
%     
%     for k = 1:observations/2;
%         if magInit(k) > 1e-12
%              trans(k) = magFinal(k)/magInit(k);
%              refl(k) = magRef(k)/magInit(k);
%         end
%     end
%     
%     trans = sqrt(trans);
%     refl = sqrt(refl);
%     hold on
%     plot(freqDom./10^12, trans, freqDom./10^12, refl, freqDom./10^12, trans+refl)
%     plot([0 100e3], [2/3 2/3], 'k-.', [0 100e3], [1/3 1/3], 'k-.', [0 100e3], [1 1], 'k-.')
%     ylabel('Transmitted/Reflected') 
%     xlabel('Frequency (THz)')
%     legend('Transmittance (E^t/E^i)', 'Reflectance(E^r/E^i)', 'Sum')
%     title('Transmission/Reflection')
%     
% peakFreq = num2str(round(primaryFreq/10^11)*10^-1);
% ppLambda = num2str(round(pointsPerWave));
% waveLeg = num2str(round(wavelengthPrimary*10^10)*10^-1);
% info1 = strcat('Points per wavelength = { } ', ppLambda, '{ } at peak frequency:{ }', peakFreq, 'THz');
% info2 = strcat('Primary wavelength = { }', waveLeg, '{ }nm');
% 
%     axis([50 1200 0 1.2])
%     text(150, .8, info1)
%     text(150, .6, info2)
%     
%     
% end

hold off
clf

end
    

movie2avi(M, 'Lorentz Med3a3', 'fps', 15);

