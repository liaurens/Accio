function preload = get_preload(defaultPreload, customPreload, preloadFactor)
    % Convenience method to query applicable preload.
    %
    % When `customPreload` is NaN, the `defaultPreload` will be used. The output preload level is multiplied by the
    % preloadFactor, to support taking 90% of the nominal preload (typically for FLS assessments).
    %
    % defaultPreload: [Nx1, double] Preload levels from bolt catalog, for N design points
    % customPreload: [double] User-defined preload level(s). Either scalar (single bolt option) or Nx1.
    % preloadFactor: [1x1, double] Factor applied to queried preload. Typically 1.0 or 0.9.

    assert(isscalar(preloadFactor), 'Expected input "preloadFactor" to be a scalar.');
    assert(any(length(customPreload) == [1 length(defaultPreload)]), ...
        'Expected size of arg "customPreload" to be scalar or equal to "defaultPreload".');

    % Enforce size of `customPreload` to be equal to `defaultPreload`
    if isscalar(customPreload)
        customPreload = ones(size(defaultPreload)) * customPreload;
    end

    preload = customPreload;
    preload(isnan(customPreload)) = defaultPreload(isnan(customPreload));
    preload = preloadFactor * preload;
end
