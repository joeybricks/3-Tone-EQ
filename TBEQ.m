
function output = TBEQ(input, Fs, LowCutoff, LowGain, MidGain, HighCutoff, HighGain, Loudness)


% Set a range of -12db to + 12db to corelate to the tone controls sliders
range = 24 

% Converting inputs to decibels
LowGain = LowGain * range - (range/2);
MidGain = MidGain * range - (range/2);
HighGain = HighGain * range - (range/2);

% ------------------------------------------------------------------
% Prepare variables
% ------------------------------------------------------------------
N = length(input);
x = input;

% Low range
GL = 10^(LowGain/20);            
wcL = 2*pi*LowCutoff/Fs; 

% High range
GH = 10^(HighGain/20);
wcH = 2*pi*HighCutoff/Fs;

% Mid range
GB = 10^(MidGain/20);
B = (wcH-wcL)
wcB = sqrt(wcH*wcL); 

% ------------------------------------------------------------------
% Create coefficients for 3 band tone control using input variables
% ------------------------------------------------------------------

% Low shelve
b0L = GL*tan(wcL/2) + sqrt(GL);
b1L = GL*tan(wcL/2) - sqrt(GL);
a0L = tan(wcL/2) + sqrt(GL);
a1L = tan(wcL/2) - sqrt(GL);

% Peak/Notch filter
b0B = sqrt(GB) + GB*tan(B/2);
b1B = -2*sqrt(GB)*cos(wcB);
b2B = sqrt(GB) - GB*tan(B/2);
a0B = sqrt(GB) + tan(B/2);
a1B = -2*sqrt(GB)*cos(wcB);
a2B = sqrt(GB) - tan(B/2);

% High shelve
b0H = sqrt(GH)*tan(wcH/2) + GH;
b1H = sqrt(GH)*tan(wcH/2) - GH;
a0H = sqrt(GH)*tan(wcH/2) + 1;
a1H = sqrt(GH)*tan(wcH/2) - 1;

% ------------------------------------------------------------------
% Normalise coefficients for 3 band tone control
% ------------------------------------------------------------------

b0L = b0L/a0L;
b1L = b1L/a0L;
a1L = a1L/a0L;
a0L = a0L/a0L;

b0B = b0B/a0B;
b1B = b1B/a0B;
b2B = b2B/a0B;
a1B = a1B/a0B;
a2B = a2B/a0B;
a0B = a0B/a0B;

b0H = b0H/a0H;
b1H = b1H/a0H;
a1H = a1H/a0H;
a0H = a0H/a0H;
% ------------------------------------------------------------------
% Declare all z delay values for 3 tone control
% ------------------------------------------------------------------ 
xZ1L = 0;
yZ1L = 0;

xZ1B = 0;
xZ2B = 0;
yZ1B = 0;
yZ2B = 0;

xZ1H = 0;
yZ1H = 0;
% ------------------------------------------------------------------
% Implement loudness emphasis 
% ------------------------------------------------------------------


% Creatig an a weighted function using matlabs built in tool
AWF = weightingFilter('a-weighting',48000);

% Switching the poles and zeros of the a weighted filter with additional
% gain weightings to create an inverse.
b0_inverse1 = 1;
b1_inverse1 = -0.224558458059779170179481866398418787867;
b2_inverse1 =  0.012606625271546399724709175416137441061;
a0_inverse1 = 1;
a1_inverse1 = 2;
a2_inverse1 = 1;
gain_inverse1 = 0.99992;

xZInv1 = 0;
xZInv2 = 0;
yZInv1 = 0;
yZInv2 = 0;

b0_inverse2 = 1;
b1_inverse2 = -1.893870494723070452280921927012968808413;
b2_inverse2 =  0.895159769094661439403637359646381810308;
a0_inverse2 = 1;
a1_inverse2 = -2;
a2_inverse2 = 1;
gain_inverse2 = 0.99992;

xZInv1_2 = 0;
xZInv2_2 = 0;
yZInv1_2 = 0;
yZInv2_2 = 0;

b0_inverse3 = 1;
b1_inverse3 = -1.994614455993021673307907803973648697138;
b2_inverse3 =  0.994621707014084477371795856015523895621;
a0_inverse3 = 1;
a1_inverse3 = -2;
a2_inverse3 = 1;
gain_inverse3 = 0.99992;

xZInv1_3 = 0;
xZInv2_3 = 0;
yZInv1_3 = 0;
yZInv2_3 = 0;


% ------------------------------------------------------------------
% Begin main time loop. 
% ------------------------------------------------------------------

for n=1:N
    
    % Difference equations are cascaded.
    
    % Low Shelf
    y_low(n) = b0L*x(n) + b1L*xZ1L - a1L*yZ1L;
    
    xZ1L = x(n);
    yZ1L = y_low(n);
    
    % Bandpass
    y_mid(n) = b0B*y_low(n) + b1B*xZ1B + b2B*xZ2B - a1B*yZ1B - a2B*yZ2B;

    xZ2B = xZ1B;
    xZ1B = y_low(n);
    yZ2B = yZ1B;
    yZ1B = y_mid(n);
    
    % High Shelf
    y_high(n) = b0H*y_mid(n) + b1H*xZ1H - a1H*yZ1H; 
    
    xZ1H = y_mid(n);
    yZ1H = y_high(n);
   
  
    % ------------------------------------------------------------------
    % Implement loudness empahsis
    % ------------------------------------------------------------------
  if (Loudness == 1) 
  
      
       y(n) = AWF(y_high(n));
         
   
   else if (Loudness == 2)
          
       yinv(n) = b0_inverse1*y_high(n) +  gain_inverse1*(b1_inverse1*xZInv1 + b2_inverse1*xZInv2 - a1_inverse1*yZInv1 - a2_inverse1*yZInv2);
       
       xZInv2 = xZInv1;
       xZInv1 = y_high(n);
       yZInv2 = yZInv1;
       yZInv1 = yinv(n);
       
       yinv1(n) = b0_inverse2*yinv(n) + gain_inverse2*(b1_inverse2*xZInv1_2 + b2_inverse2*xZInv2_2 - a1_inverse2*yZInv1_2 - a2_inverse2*yZInv2_2);
       
       xZInv2_2 = xZInv1_2;
       xZInv1_2 = yinv(n);
       yZInv2_2 = yZInv1_2;
       yZInv1_2 = yinv1(n);
       
       yinv2(n) = b0_inverse3*yinv1(n) + gain_inverse2*(b1_inverse3*xZInv1_3 + b2_inverse3*xZInv2_3 - a1_inverse3*yZInv1_3 - a2_inverse3*yZInv2_3);
       
       xZInv2_3 = xZInv1_3;
       xZInv1_3 = yinv1(n);
       yZInv2_3 = yZInv1_3;
       yZInv1_3 = yinv2(n);
       
       yinv3(n) = yinv2(n)*0.099;
       
       y(n) = yinv3(n);
           
       
       else
       
       y(n) = y_high(n);
      
       end
     end
  end 
  

output = y; 
end

