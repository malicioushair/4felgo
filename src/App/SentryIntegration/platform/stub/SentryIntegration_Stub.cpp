#include "../../SentryIntegration.h"

namespace SentryIntegration {

namespace {

class SentryStub
	: public ISentry
{
public:
	bool Initialize(const QString &) override
	{
		return true;
	}

	void Shutdown() override
	{
	}

	void AddBreadcrumb(const std::string &, const std::string &) override
	{
	}

	void CaptureException(const QString &, const QString &) override
	{
	}

	void Flush() override
	{
	}
};

SentryStub g_stubPlatform;

} // namespace

ISentry & GetPlatform()
{
	return g_stubPlatform;
}

} // namespace SentryIntegration
