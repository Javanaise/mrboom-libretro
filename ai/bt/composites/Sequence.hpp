#pragma once

#include "../Composite.hpp"

namespace bt
{

/*
    The Sequence composite ticks each child node in order.
    If a child fails or runs, the sequence returns the same status.
    In the next tick, it will try to run each child in order again.
    If all children succeeds, only then does the sequence succeed.
 */
class Sequence : public Composite
{
public:
void Initialize()
{
	index = 0;
}

Status Update()
{
	if (HasNoChildren())
		return Success;

	// Keep going until a child behavior says it's running.
	while (1)
	{
		bt::Node * child = children.at(index);
		bt::Status status = child->Tick();

		// If the child fails, or keeps running, do the same.
		if (status != Success)
			return status;

		// Hit the end of the array, job done!
		if (++index == (signed)children.size())
			return Success;
	}
}
};

}
