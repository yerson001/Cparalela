#include "threadpool.hpp"

template <typename tuple_t, typename bmask_t>
void atomic_update(tuple_t tuple, bmask_t bmask)
{
    typedef typename tuple_t::value_t value_t;

    auto g_state = global_state.load();
    auto l_value = tuple.value;
    state_t<bmask_t, value_t> target;

    do
    {
        // exit if solution is not optimal
        if (g_state.value > l_value)
            return;

        // construct the desired target
        target.value = l_value;
        target.bmask = bmask;
    } while (!global_state.compare_exchange_weak(g_state, target));
}

int main()
{
    ThreadPool TP(2); // 2 threads are sufficient
    // initialize tuples with random values
    init_tuples(tuples, num_items);
    // traverse left and right branch
    TP.spawn(traverse<index_t, tuple_t, bmask_t>, 0, tuple_t(0, 0), 0);
    TP.spawn(traverse<index_t, tuple_t, bmask_t>, 0, tuple_t(0, 0), 1);
    // wait for all tasks to be finished
    TP.wait_and_stop();
    // report the final solution
    auto g_state = global_state.load();
    std::cout << "value " << g_state.value << std::endl;
    auto bmask = g_state.bmask;
    for (index_t i = 0; i < num_items; i++)
    {
        std::cout << bmask % 2 << " ";
        bmask >>= 1;
    }
    std::cout << std::endl;
}