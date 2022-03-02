clc, clear all;
T = dctmtx(8);
%% reading the Original Image inorder to calculate Average Mean Error
I = imread('Sampleimage.tif');
%[height,width,ch] = size(I);
%%
tcpipServer = tcpip('0.0.0.0', 30000, 'NetworkRole', 'Server');
set(tcpipServer,'InputBufferSize',300000);
set(tcpipServer,'Timeout',5); %Waiting time in seconds to complete read and write operations
fopen(tcpipServer);
get(tcpipServer, 'BytesAvailable');


tcpipServer.BytesAvailable; 
DataReceived =[];
 pause(0.1);
while (get(tcpipServer, 'BytesAvailable') > 0) 
    
    tcpipServer.BytesAvailable;
    rawData = fread(tcpipServer,300000/8,'double');
    DataReceived = [DataReceived; rawData];
    pause(0.1)
    size(rawData,1) 
    %disp(tcpipServer.BytesAvailable)
    %disp(tcpipServer)
end
fclose(tcpipServer)
delete(tcpipServer); 
clear tcpipServer 

[h,w,c] = size(DataReceived);
new = reshape(DataReceived,[h/2,2]);

im = new(:, 1);
im = im.';
in = new(:, 2);
in=in.';
%% Process Run-Length-Decoding function on the image which has been received
Immmmm=rl_dec(im, in);


%% Process izigzag function on the image which has been Quantized
Image5 = invzigzag(Immmmm,256, 256);
Image5 = reshape(Image5,256,256,1);

%% Process IDCT function on the 8*8 block by block image which has been Quantized
invdct = @(block_struct) T' * block_struct.data * T;
I2 = blockproc(Image5,[8 8],invdct);
%% Showing the original Image
figure
imshow(I)
title('Original Image')
%% Showing the output Image
figure
imshow(I2)
title('Image after IDCT')
%% getting the Double of Input and Output Images
Input = double(I);
Output = double(I2);
%% Calculating mean-squared error between the two images.
err = immse(Input, Output);
fprintf('\n The mean-squared error is %0.4f\n', err)


function bytes = bytesPerElement(x)
    w = whos('x');
    bytes = w.bytes / numel(x);
end
%% Izigzag Function
function out=invzigzag(in,num_rows,num_cols)
tot_elem=length(in);
if nargin>3
	error('Too many input arguments');
elseif nargin<3
	error('Too few input arguments');
end
% Check if matrix dimensions correspond
if tot_elem~=num_rows*num_cols
	error('Matrix dimensions do not coincide');
end
% Initialise the output matrix
out=zeros(num_rows,num_cols);
cur_row=1;	cur_col=1;	cur_index=1;
% First element
%out(1,1)=in(1);
while cur_index<=tot_elem
	if cur_row==1 && mod(cur_row+cur_col,2)==0 && cur_col~=num_cols
		out(cur_row,cur_col)=in(cur_index);
		cur_col=cur_col+1;							%move right at the top
		cur_index=cur_index+1;
		
	elseif cur_row==num_rows && mod(cur_row+cur_col,2)~=0 && cur_col~=num_cols
		out(cur_row,cur_col)=in(cur_index);
		cur_col=cur_col+1;							%move right at the bottom
		cur_index=cur_index+1;
		
	elseif cur_col==1 && mod(cur_row+cur_col,2)~=0 && cur_row~=num_rows
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row+1;							%move down at the left
		cur_index=cur_index+1;
		
	elseif cur_col==num_cols && mod(cur_row+cur_col,2)==0 && cur_row~=num_rows
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row+1;							%move down at the right
		cur_index=cur_index+1;
		
	elseif cur_col~=1 && cur_row~=num_rows && mod(cur_row+cur_col,2)~=0
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row+1;		cur_col=cur_col-1;	%move diagonally left down
		cur_index=cur_index+1;
		
	elseif cur_row~=1 && cur_col~=num_cols && mod(cur_row+cur_col,2)==0
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row-1;		cur_col=cur_col+1;	%move diagonally right up
		cur_index=cur_index+1;
		
	elseif cur_index==tot_elem						%input the bottom right element
        out(end)=in(end);							%end of the operation
		break										%terminate the operation
    end
end
end
%% Run_Length Decoding Function
function x=rl_dec(d,c)
% This function performs Run Length Dencoding to the elements of the strem 
% of data d according to their number of apperance given in c. There is no 
% restriction on the format of the elements of d, while the elements of c 
% must all be integers.
% This function is built by Abdulrahman Ikram Siddiq in Oct-1st-2011 5:36pm.
 
if nargin<2
    error('not enough number of inputs')
end
x=[];
for i=1:length(d)
x=[x d(i)*ones(1,c(i))];
end
end