function mask = regiongrowing(I, x, y, tolerance, max_area)
    [rows, cols] = size(I);
    mask = false(rows, cols);
    visited = false(rows, cols);
    seed_value = I(y, x);
    stack = [y, x];

    while ~isempty(stack)
        current_y = stack(end, 1);
        current_x = stack(end, 2);
        stack(end, :) = [];

        if current_y > 0 && current_y <= rows && current_x > 0 && current_x <= cols && ...
           ~visited(current_y, current_x) && ~mask(current_y, current_x)
            diff = abs(I(current_y, current_x) - seed_value);
            if diff <= tolerance
                mask(current_y, current_x) = true;
                visited(current_y, current_x) = true;
                if sum(mask(:)) <= max_area % Limit growth by area
                    stack = [stack; current_y+1, current_x; current_y-1, current_x; ...
                             current_y, current_x+1; current_y, current_x-1];
                end
            end
        end
    end
end