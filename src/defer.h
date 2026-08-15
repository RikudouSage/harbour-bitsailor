#pragma once

#include <utility>
#include <type_traits>

template <typename TCleanup>
class ScopeExit {
public:
    explicit ScopeExit(TCleanup&& cleanupFunction)
        : cleanupFunction(std::forward<TCleanup>(cleanupFunction))
    {
    }

    ScopeExit(const ScopeExit&) = delete;
    ScopeExit& operator=(const ScopeExit&) = delete;
    ScopeExit(ScopeExit&&) = delete;
    ScopeExit& operator=(ScopeExit&&) = delete;

    ~ScopeExit()
    {
        cleanupFunction();
    }

private:
    TCleanup cleanupFunction;
};

template <typename TCleanup>
ScopeExit<std::decay_t<TCleanup>> scopeExit(TCleanup&& cleanupFunction)
{
    return ScopeExit<std::decay_t<TCleanup>>(
        std::forward<TCleanup>(cleanupFunction)
    );
}

#define DEFER_CONCATENATE_IMPL(left, right) left##right
#define DEFER_CONCATENATE(left, right) DEFER_CONCATENATE_IMPL(left, right)

#define defer(...) \
    [[maybe_unused]] auto DEFER_CONCATENATE(scopeExitGuard_, __COUNTER__) = \
        scopeExit([&] __VA_ARGS__)
