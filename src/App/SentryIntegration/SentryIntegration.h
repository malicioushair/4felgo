#pragma once

#include <QString>
#include <string>

namespace SentryIntegration {

class ISentry
{
public:
	virtual ~ISentry() = default;
	virtual bool Initialize(const QString & release) = 0;
	virtual void Shutdown() = 0;
	virtual void AddBreadcrumb(const std::string & message, const std::string & level) = 0;
	virtual void CaptureException(const QString & message, const QString & type) = 0;
	virtual void Flush() = 0;
};

ISentry & GetPlatform();

bool InitSentry(const QString & release);

void InstallBreadcrumbSink();

void InstallExceptionHandler();

} // namespace SentryIntegration
