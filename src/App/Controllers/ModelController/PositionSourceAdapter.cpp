/*!
    \class PositionSourceAdapter
    \inmodule PastViewer
    \brief Wrapper around QGeoPositionInfoSource for QML consumption.

    Registered as an uncreatable type in the \c PastViewer QML module.
 */
#include "PositionSourceAdapter.h"

#include <limits>

namespace {

// 5m is just an arbitrary number to prevent dirrection jitter
constexpr auto MIN_DISTANCE_METERS = 5.0;

enum class BearingSource
{
	None,
	Calculated,
};

}

struct PositionSourceAdapter::Impl
{
	Impl(const QGeoPositionInfoSource & source)
		: source(source)
	{}

	const QGeoPositionInfoSource & source;
	QGeoPositionInfo position;
	QGeoCoordinate lastValidCoordinate;
	QGeoCoordinate previousCoordinate;
	double bearing { std::numeric_limits<double>::quiet_NaN() };
	BearingSource bearingSource { BearingSource::None };
	bool positionAvailable { true };
};

PositionSourceAdapter::PositionSourceAdapter(const QGeoPositionInfoSource & source, QObject * parent)
	: QObject(parent)
	, m_impl(std::make_unique<Impl>(source))
{
	connect(&m_impl->source, &QGeoPositionInfoSource::positionUpdated, this, &PositionSourceAdapter::OnPositionUpdated);
}

PositionSourceAdapter::~PositionSourceAdapter() = default;

/*!
    Returns the latest position information object.
*/
QGeoPositionInfo PositionSourceAdapter::Position() const
{
	return m_impl->position;
}

/*!
    Returns the latest valid device coordinate.
*/
QGeoCoordinate PositionSourceAdapter::Coordinate() const
{
	const auto currentCoord = Position().coordinate();
	return currentCoord.isValid() ? currentCoord : m_impl->lastValidCoordinate;
}

/*!
    Returns the latest device heading in degrees.
*/
double PositionSourceAdapter::Bearing() const
{
	return m_impl->bearing;
}

/*!
    Returns whether a valid position fix is available.
*/
bool PositionSourceAdapter::IsPositionAvailable() const
{
	return m_impl->positionAvailable;
}

void PositionSourceAdapter::OnPositionUpdated(const QGeoPositionInfo & info)
{
	const auto currentCoord = info.coordinate();

	if (currentCoord.isValid())
	{
		m_impl->positionAvailable = true;
		emit PositionAvailableChanged();

		if (m_impl->previousCoordinate.isValid())
		{
			const auto distance = m_impl->previousCoordinate.distanceTo(currentCoord);

			if (distance >= MIN_DISTANCE_METERS)
			{
				m_impl->bearing = m_impl->previousCoordinate.azimuthTo(currentCoord);
				m_impl->bearingSource = BearingSource::Calculated;
				m_impl->previousCoordinate = currentCoord;
			}
		}
		else
		{
			m_impl->previousCoordinate = currentCoord;
			m_impl->bearing = std::numeric_limits<double>::quiet_NaN(); // No bearing until we have movement
			m_impl->bearingSource = BearingSource::None;
		}

		m_impl->lastValidCoordinate = currentCoord;
		m_impl->position = info;
		emit PositionChanged();
	}
	else
	{
		m_impl->positionAvailable = false;
		emit PositionAvailableChanged();
	}
}

/*!
    \property PositionSourceAdapter::coordinate

    Holds the latest valid device coordinate.
*/

/*!
    \property PositionSourceAdapter::bearing

    Holds the device heading in degrees, where zero is north.
*/

/*!
    \property PositionSourceAdapter::positionAvailable

    Holds whether a valid position fix is available.
*/

/*!
    \fn void PositionSourceAdapter::PositionChanged()

    Emitted when \l coordinate or \l bearing changes.
*/

/*!
    \fn void PositionSourceAdapter::PositionAvailableChanged()

    Emitted when \l positionAvailable changes.
*/
