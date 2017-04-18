#pragma once

#include <memory>
#include <vector>

namespace bt
{

enum Status
{
	Invalid,
	Success,
	Failure,
	Running
};

class Node
{
public:

Node() {
	status = Invalid;
}

virtual ~Node() {
}

virtual Status Update() = 0;
virtual void Initialize() {
}
virtual void Terminate(Status s) {
}

Status Tick()
{
	if (status != Running)
		Initialize();

	status = Update();

	if (status != Running)
		Terminate(status);

	return status;
}

bool IsSuccess() const {
	return status == Success;
}
bool IsFailure() const {
	return status == Failure;
}
bool IsRunning() const {
	return status == Running;
}
bool IsTerminated() const {
	return IsSuccess() || IsFailure();
}
void Reset() {
	status = Invalid;
}

protected:
Status status;
};

//using Nodes = std::vector<Node *>;

}
