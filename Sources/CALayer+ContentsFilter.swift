/*
 * Apples CALayerContentsFilter is a struct with static members, for backwards compatibility.
 * We implemented it with an enum, which can be used the same way as Apples CALayerContentsFilter.
 *
 * Apple's `.nearest` and `magnificationFilter` are missing: SDL_gpu sets the minification and magnification
 * filters from a single value, so neither would behave the way it does on iOS. Failing to compile is better
 * than differing quietly.
 */
public enum CALayerContentsFilter {
    case linear
    case trilinear
}
