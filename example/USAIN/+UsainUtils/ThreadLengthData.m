classdef ThreadLengthData < matlab.mixin.SetGet
    % TODO: Rename to ThreadLengthResults? That's maybe more descriptive

    properties
        len double  % Thread length
        utilization double  % Utilization ratio
        flangeSide string % upper or lower
    end

    methods

        function Obj = ThreadLengthData(flangeSide, len)
            % Stores results on thread length requirements for a single 'location' of a fastener
            % A 'location' is a combination of side (either free or fixed) and position relative to the nut
            % (either visible or gripped).
            %
            % flangeSide: Side of the flange connection for this 'location'
            % len: Length of thread on considered side of fastener

            Obj.flangeSide = flangeSide;
            Obj.len = len;
        end

        function calc_utilization(Obj, minimum, maximum)
            % Computes utilization ratio for stored thread length
            %
            % minimum: Minimum required thread length
            % maximum: Optional. Maximum allowed thread length. If not provided, maximum will not be checked.

            if nargin < 3
                maximum = Inf; % Maximum needs not be checked
            end

            % Compute worst-case utilization from maximum and minimum. If the thread length is negative, make
            % sure an infeasible utilization is stored (not expected to happen, but implemented for
            % robustness)
            lenForCalc = Obj.len;
            lenForCalc(lenForCalc == 0) = 1e-10;
            Obj.utilization = max(max( ...
                minimum ./ lenForCalc, ...
                lenForCalc ./ maximum), ...
                double(Obj.len <= 0) + -Obj.len .* double(Obj.len <= 0));
        end

        function zero_utilization_for_hex_bolt(Obj, fastenerType)
            % Hex bolts do not have threads on the "fixed side" because of the bolt head
            % This method forces `utilization` to 0.0 for hex bolts

            isHexBolt = strcmpi(fastenerType, 'hex');
            if isHexBolt
                Obj.utilization = 0;
            end
        end

    end
end
