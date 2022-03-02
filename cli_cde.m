clear; clc;
%% Reading the image
I = imread('SampleImage.tif');
I = im2double(I);

T = dctmtx(8);
dct = @(block_struct) T * block_struct.data * T'; %creating function to calculate DCT

%% DCT Transformation 
B = blockproc(I,[8 8],dct); %creating An 8*8 block 
%% creating mask to use in Quantizastion method
mask = zeros(8,8);
quality=2; % defining the quality of Quantization method 
mask(1:quality,1:quality) = 1;

%% Process  Quantization  on 8*8 image  block by block  
B2 = blockproc(B,[8 8],@(block_struct) mask .* block_struct.data);

%% Process zigzag function on the image which has benn Quantized
Image4 = zigzag(B2);

%% Process Runlength Encoding the image which has benn Quantized
[im in]=my_RLE(Image4);

%% Sending the data on server side
send=[im in];
data = send(:);

size(data)

%% extracting the detail of data to determine the optimal buffersize
s = whos('data')
s.size;
s.bytes;
%% Creation of TCP function for Client side
tcpipClient = tcpip('localhost', 30000, 'NetworkRole', 'client');
set(tcpipClient, 'OutputBufferSize', s.bytes);
fopen(tcpipClient);
    fwrite(tcpipClient, data(:), 'double');
fclose(tcpipClient);

function bytes = bytesPerElement(x)
    w = whos('x');
    bytes = w.bytes ;
end
%%   zigzag function
function output = zigzag(in)
% initializing the variables
%----------------------------------
h = 1;
v = 1;
vmin = 1;
hmin = 1;
vmax = size(in, 1);
hmax = size(in, 2);
i = 1;
output = zeros(1, vmax * hmax);
%----------------------------------
while ((v <= vmax) && (h <= hmax))
    
    if (mod(h + v, 2) == 0)                 % going up
        if (v == vmin)       
            output(i) = in(v, h);        % if we got to the first line
            if (h == hmax)
	      v = v + 1;
	    else
              h = h + 1;
            end
            i = i + 1;
        elseif ((h == hmax) && (v < vmax))   % if we got to the last column
            output(i) = in(v, h);
            v = v + 1;
            i = i + 1;
        elseif ((v > vmin) && (h < hmax))    % all other cases
            output(i) = in(v, h);
            v = v - 1;
            h = h + 1;
            i = i + 1;
        end
        
    else                                    % going down
       if ((v == vmax) && (h <= hmax))       % if we got to the last line
            output(i) = in(v, h);
            h = h + 1;
            i = i + 1;
        
       elseif (h == hmin)                   % if we got to the first column
            output(i) = in(v, h);
            if (v == vmax)
	      h = h + 1;
	    else
              v = v + 1;
            end
            i = i + 1;
       elseif ((v < vmax) && (h > hmin))     % all other cases
            output(i) = in(v, h);
            v = v + 1;
            h = h - 1;
            i = i + 1;
       end
    end
    if ((v == vmax) && (h == hmax))          % bottom right element
        output(i) = in(v, h);
        break
    end
end
end
%% Runing Runlength Encoding function
function [d,c]=my_RLE(x);
% This function performs Run Length Encoding to a strem of data x. 
% [d,c]=rl_enc(x) returns the element values in d and their number of
% apperance in c. All number formats are accepted for the elements of x.
% This function is built by Abdulrahman Ikram Siddiq in Oct-1st-2011 5:15pm.
if nargin~=1
    error('A single 1-D stream must be used as an input')
end
ind=1;
d(ind)=x(1);
c(ind)=1;
for i=2 :length(x)
    if x(i-1)==x(i)
       c(ind)=c(ind)+1;
    else ind=ind+1;
         d(ind)=x(i);
         c(ind)=1;
    end
end
end