close all
clear

% Input frame
I = imread("lane_1.jpeg");   % read the frame
    
% Grayscale & Gamma correction    
gray = rgb2gray(I);    
[r,c]=size(gray);
gray = imadjust(gray,[],[],2);    
    
% Binarize
level = graythresh(gray); %Otsu method
I_bw = imbinarize(gray,level);

% Region of interst 
masked = find_area(I_bw);


% Houghline detection
[left,right] = hough_lines(masked);

% Compute the average line
left_line = get_line(I,left);
right_line = get_line(I,right);

% Display line on image
line_image = draw_line(I,left_line,right_line);

% Output frame
figure,imshow(line_image);



function area = find_area(edged_image)
    [r,c] = size(edged_image);
    x = [0  c*3/7 c*4/7  c];
    y = [r  r/2 r/2  r];
    tri = roipoly(edged_image,x,y);
    area = bitand(edged_image,tri);

end

function [left_lines,right_lines] = hough_lines(masked_image)
    left_lines = [];
    right_lines = [];
    % detect left lines
    [H,T,R] = hough(masked_image,'theta',20:0.1:80);
    P = houghpeaks(H,3,'threshold',80);
    if(length(P)~= 0)
        left_lines = houghlines(masked_image,T,R,P,'FillGap',40,'MinLength',5);      
    end
    % detect right lines
    [H,T,R] = hough(masked_image,'theta',-80:0.1:-20);
    P = houghpeaks(H,5,'threshold',80);
    if(length(P)~= 0)
        right_lines = houghlines(masked_image,T,R,P,'FillGap',40,'MinLength',5);
    end
end

function line = get_line(image,lines)
    line_fit =[];
    count = 1;
    % Calculate the average slope & intercept for right line & left line
        for i=1:length(lines)
            x1 = lines(i).point1(1);
            y1 = lines(i).point1(2);
            x2 = lines(i).point2(1);
            y2 = lines(i).point2(2);
            p = polyfit([x1,x2],[y1,y2],1);
            slope = p(1);
            interc = p(2); 
            line_fit(count,:) = [slope,interc];
            count = count+1 ;

        end
    if count == 2 % means line_fit has only one data
        line_ave = line_fit;
    else
        line_ave = mean(line_fit); 
    end
    
    % transform slope & intercept to point-slope-form 
    if isempty(line_fit)
        line = last_lines;
    else
        line = coordinate(image,line_ave);
    end
    
end

function xy = coordinate(image,p)
r= size(image,1);
slope = p(1);
interc = p(2);
y1 = r;
y2 = y1*(3/5);
x1 = (y1-interc)/slope ;
x2 = (y2-interc)/slope ;
xy = [x1,y1,x2,y2];
end


function line_imgae = draw_line(image,left_line,right_line)
    line_imgae = insertShape(image,'Line',[left_line;right_line],'LineWidth',8);
end
