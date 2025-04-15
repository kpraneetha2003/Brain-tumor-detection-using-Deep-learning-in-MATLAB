clc;
clear all;
close all;

% Read and preprocess image
img = imread('C:\Users\Praneetha\OneDrive\Desktop\help\tumor\cat1_resized.jpg');
if size(img, 3) == 3
    img_gray = rgb2gray(img);
else
    img_gray = img;
end

% Resize to target size
target_size = [128 128];
img_resized = imresize(img_gray, target_size);

% Enhance contrast and brightness
enhanced = imadjust(img_resized, [0.2 0.98], []);
enhanced = adapthisteq(enhanced, 'ClipLimit', 0.06);

% Get intensity variation
intensity_std = std(double(enhanced(:)));

% Initial tumor detection using stricter intensity thresholding
sorted_intensities = sort(enhanced(:), 'descend');
threshold = sorted_intensities(round(numel(sorted_intensities) * 0.03)); % Top 3%
tumor = enhanced > threshold * 0.75;

% Apply a mask to exclude outer boundaries (focus on center)
center_mask = false(size(tumor));
center_y = round(size(tumor, 1) / 2);
center_x = round(size(tumor, 2) / 2);
radius = min(center_y, center_x) * 0.6;
[yy, xx] = meshgrid(1:size(tumor, 2), 1:size(tumor, 1));
circle = (xx - center_x).^2 + (yy - center_y).^2 <= radius^2;
tumor = tumor & circle;

% Edge detection to refine boundaries
edges = edge(enhanced, 'canny', 0.5);
tumor = tumor & ~edges;

% ... your preprocessing code remains the same ...
% Define structuring elements (must be declared before usage)
se1 = strel('disk', 2);
se2 = strel('disk', 6);


% ---- UPDATED: Morphological and shape filtering ----
tumor = imopen(tumor, se1);
tumor = imclose(tumor, se2);
tumor = imfill(tumor, 'holes');

% Remove small objects and false detections
tumor = bwareaopen(tumor, 30);  % increased from 5 to 30 to remove noise

% ---- NEW: Filter regions by shape (eccentricity, area) ----
stats = regionprops(tumor, 'Area', 'Eccentricity', 'PixelIdxList');
tumor_mask = false(size(tumor));
for i = 1:length(stats)
    area = stats(i).Area;
    ecc = stats(i).Eccentricity;
    if area > 50 && ecc < 0.95 % filter out overly round regions
        tumor_mask(stats(i).PixelIdxList) = true;
    end
end

% ---- Reapply center mask ----
tumor_mask = tumor_mask & circle;

% ---- Tighter condition to reject tiny or suspicious detections ----
tumor_area_ratio = sum(tumor_mask(:)) / numel(tumor_mask);
if tumor_area_ratio < 0.001 || intensity_std < 10 || sum(tumor_mask(:)) < 60
    tumor_mask = false(size(tumor_mask)); % No tumor
end


% Visualization
figure('Position', [100 100 1200 500]);

subplot(1, 2, 1);
imshow(img_resized);
title(['Original MRI Image (H x W=', num2str(target_size(1)), 'x', num2str(target_size(2)), ')']);
hold on;
contours = bwboundaries(tumor_mask);
for k = 1:length(contours)
    boundary = contours{k};
    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
end
hold off;

subplot(1, 2, 2);
tumor_vis = uint8(zeros([target_size 3]));
tumor_vis(:,:,3) = 128; % Dark blue background
for i = 1:3
    channel = tumor_vis(:,:,i);
    channel(tumor_mask) = 255; % White tumor
    tumor_vis(:,:,i) = channel;
end
imshow(tumor_vis);

if sum(tumor_mask(:)) == 0
    title('No Tumor Detected');
else
    title('Tumor Masked in White');
end

hold on;
for k = 1:length(contours)
    boundary = contours{k};
    plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 1);
end
hold off;
