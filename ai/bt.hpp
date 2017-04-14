#pragma once
#pragma GCC diagnostic ignored "-Wunused-function"

#include "bt/BehaviorTree.hpp"
#include "bt/Blackboard.hpp"
#include "bt/Composite.hpp"
#include "bt/Decorator.hpp"
#include "bt/Leaf.hpp"
#include "bt/Node.hpp"

// composites
#include "bt/composites/Selector.hpp"
#include "bt/composites/Sequence.hpp"

// decorators
#include "bt/decorators/Failer.hpp"
#include "bt/decorators/Succeeder.hpp"
