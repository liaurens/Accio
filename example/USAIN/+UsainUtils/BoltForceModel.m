classdef BoltForceModel < logging.Config
    % Base class for bolt force transfer function

    methods (Abstract)
        % Store data to plot transfer function (for DOCTOR)
        %
        % FlangeModel: [UsainUtils.FlangeModel or UsainUtils.SelectedModel]
        store_plot_data(Obj, FlangeModel)

        % Compute force in bolt according to bolt force transfer function
        %
        % fApplied: [double, K*M] Flange segment force (applied force) for K design points and M load bins
        % iCalc:    [double, K*1] Index mask for design point selection. All design points considered if not
        %           input.
        %
        % fBolt:    [double, K*M] Bolt force
        fBolt = get_bolt_force(Obj, fApplied, iCalc)

        % Returns selection mask for design points that use flange width dependent regions in the bolt
        % force model (given the maximum segment force).
        % To be used for computational efficiency; if there is no dependency on flange width, the number of
        % computations can be reduced.
        %
        % fApplied: [double, K*1] Max. flange segment force (applied force) for K design points
        bool = is_width_dependent(Obj, fApplied)

        % Logs summary of bolt force model
        msg = get_intermediate_results(Obj)
    end
end
