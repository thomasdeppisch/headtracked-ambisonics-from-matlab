function [yaw,pitch,roll] = quat2euler(quat)

% yaw
yaw = atan2(2.0 * (quat(1) .* quat(4) + quat(2) .* quat(3)), 1.0 - 2.0 * (quat(3) .* quat(3) + quat(4) .* quat(4)));

% pitch
sinTemp = 2.0 * (quat(1) .* quat(3) - quat(4) .* quat(2));
if (abs(sinTemp) >= 1)
  pitch = pi/2*sign(sinTemp);
else
  pitch = asin(sinTemp);
end

% roll
roll = atan2(2.0 * (quat(1) .* quat(2) + quat(3) .* quat(4)), 1.0 - 2.0 * (quat(2) .* quat(2) + quat(3) .* quat(3)));