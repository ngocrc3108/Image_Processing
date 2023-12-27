inputFile = '480-360.bmp';
outputFile = '480-360.hex';
width = 480;
height = 360;

b=imread(inputFile); % 24-bit BMP image RGB888 

k=1;
for i=height:-1:1 % image is written from the last row to the first row
for j=1:width
a(k)=b(i,j,1);
a(k+1)=b(i,j,2);
a(k+2)=b(i,j,3);
k=k+3;
end
end

fid1 = fopen(inputFile, 'rb');

% Read BMP header (first 54 bytes)
header = fread(fid1, 54, 'uint8');
fclose(fid1);

fid = fopen(outputFile, 'wt');
fprintf(fid, '%x\n', header);
fprintf(fid, '%x\n', a);
fclose(fid);