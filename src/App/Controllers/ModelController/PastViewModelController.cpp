/*!
    \namespace ModelType
    \inmodule PastViewer
    \brief Selects which QAbstractItemModel to display in QML.
 */

/*!
    \enum ModelType::Type

    \value Clustered Map marker model with clustering applied.
    \value Raw Flat list of individual photos.
 */

/*!
    \class PastVuModelController
    \inmodule PastViewer
    \brief Central controller for photo data, map viewport, and user filters.

    Owns the model stack and is registered as the QML context property
    \c pastVuModelController.
 */
#include "PastViewModelController.h"

#include <memory>
#include <stdexcept>

#include <QGuiApplication>
#include <QLocationPermission>
#include <QString>

#include "App/Models/ClusterModel.h"
#include "glog/logging.h"

#include "App/Controllers/ModelController/PositionSourceAdapter.h"
#include "App/Models/BaseModel.h"
#include "App/Models/NearestObjectsModel.h"
#include "App/Models/ScreenObjectsModel.h"

namespace {
constexpr auto NEAREST_OBJECTS_ONLY = "NearestObjectsOnly";
constexpr auto HISTORY_NEAR_MODEL_TYPE = "HistoryNearModelType";
constexpr auto YEARS_FROM = "YEARS_FROM";
constexpr auto YEARS_TO = "YEARS_TO";
constexpr auto YEAR_FROM_VALUE = 1800;
}

struct PastVuModelController::Impl
{
	Impl(const QLocationPermission & permission, QSettings & settings)
		: source(QGeoPositionInfoSource::createDefaultSource(nullptr))
		, baseModel(std::make_unique<BaseModel>(source.get()))
		, screenObjectsModel(std::make_unique<ScreenObjectsModel>(baseModel.get()))
		, nearestObjectsModel(std::make_unique<NearestObjectsModel>(screenObjectsModel.get(), source.get()))
		, clusterModelScreen(std::make_unique<ClusterModel>(screenObjectsModel.get()))
		, clusterModelNearest(std::make_unique<ClusterModel>(nearestObjectsModel.get()))
		, positionSourceAdapter([&] {
			if (!source)
				throw std::runtime_error("POSITION SOURCE EMPTY!");
			return std::make_unique<PositionSourceAdapter>(*source);
		}())
		, settings(settings)
	{
		if (qApp->checkPermission(permission) == Qt::PermissionStatus::Granted)
			source->startUpdates();
	}

	std::unique_ptr<QGeoPositionInfoSource> source;
	QGeoRectangle viewPort;
	std::unique_ptr<BaseModel> baseModel;
	std::unique_ptr<ScreenObjectsModel> screenObjectsModel;
	std::unique_ptr<NearestObjectsModel> nearestObjectsModel;
	std::unique_ptr<ClusterModel> clusterModelScreen;
	std::unique_ptr<ClusterModel> clusterModelNearest;
	std::unique_ptr<PositionSourceAdapter> positionSourceAdapter;
	QSettings & settings;
	const Range defaultTimelineRange { YEAR_FROM_VALUE, QDate::currentDate().year() };
	Range userSelectedTimelineRange {
		settings.value(YEARS_FROM, defaultTimelineRange.min).toInt(),
		settings.value(YEARS_TO, defaultTimelineRange.max).toInt()
	};
};

PastVuModelController::PastVuModelController(const QLocationPermission & permission, QSettings & settings, QObject * parent)
	: QObject(parent)
	, m_impl(std::make_unique<Impl>(permission, settings))
{
	connect(this, &PastVuModelController::PositionPermissionGranted, m_impl->baseModel.get(), &BaseModel::OnPositionPermissionGranted);
	connect(this, &PastVuModelController::UserSelectedTimelineRangeChanged, m_impl->screenObjectsModel.get(), &ScreenObjectsModel::OnUserSelectedTimelineRangeChanged);
	connect(m_impl->baseModel.get(), &BaseModel::LoadingItems, this, &PastVuModelController::loadingItems);
	connect(m_impl->baseModel.get(), &BaseModel::ItemsLoaded, this, [&]() {
		emit itemsLoaded();
		m_impl->clusterModelScreen->OnViewportChanged(m_impl->viewPort);
		m_impl->clusterModelNearest->OnViewportChanged(m_impl->viewPort);
	});
	connect(m_impl->baseModel.get(), &BaseModel::ItemsLoaded, m_impl->clusterModelScreen.get(), [&]() {
		m_impl->clusterModelScreen->OnViewportChanged(m_impl->baseModel->GetLastKnownViewport());
	});
	connect(m_impl->baseModel.get(), &BaseModel::ItemsLoaded, m_impl->clusterModelNearest.get(), [&]() {
		m_impl->clusterModelScreen->OnViewportChanged(m_impl->baseModel->GetLastKnownViewport());
	});
	connect(m_impl->clusterModelScreen.get(), &ClusterModel::ZoomsToDecluster, m_impl->screenObjectsModel.get(), &ScreenObjectsModel::UpdateZoomsToDecluster);
}

PastVuModelController::~PastVuModelController() = default;

/*!
    Returns the model selected by \a modelType.
*/
QAbstractItemModel * PastVuModelController::GetModel(ModelType::Type modelType)
{
	switch (modelType)
	{
		case ModelType::Raw:
			return GetHistoryNearModelType() // @TODO think on the function name
					 ? static_cast<QAbstractItemModel *>(m_impl->screenObjectsModel.get())
					 : static_cast<QAbstractItemModel *>(m_impl->nearestObjectsModel.get());
		case ModelType::Clustered:
			return GetNearestObjectsOnly()
					 ? static_cast<QAbstractItemModel *>(m_impl->clusterModelNearest.get())
					 : static_cast<QAbstractItemModel *>(m_impl->clusterModelScreen.get());
	}
	assert(false && "Unknown model type");
}

/*!
    Returns the map-host API key compiled into the application.
*/
QString PastVuModelController::GetMapHostApiKey()
{
	return QString::fromUtf8(API_KEY);
}

/*!
    Returns the position adapter used by the QML map and compass.
*/
PositionSourceAdapter * PastVuModelController::GetPositionSource()
{
	return m_impl->positionSourceAdapter.get();
}

/*!
    Forwards a location-permission grant to the underlying models.
*/
void PastVuModelController::OnPositionPermissionGranted()
{
	emit PositionPermissionGranted();
}

bool PastVuModelController::GetNearestObjectsOnly()
{
	return m_impl->settings.value(NEAREST_OBJECTS_ONLY).toBool();
}

void PastVuModelController::SetNearestObjectsOnly(bool value)
{
	m_impl->settings.setValue(NEAREST_OBJECTS_ONLY, value);
	emit NearestObjectsOnlyChanged();
}

bool PastVuModelController::GetHistoryNearModelType()
{
	return m_impl->settings.value(HISTORY_NEAR_MODEL_TYPE).toBool();
}

void PastVuModelController::SetHistoryNearModelType(bool value)
{
	m_impl->settings.setValue(HISTORY_NEAR_MODEL_TYPE, value);
	emit HistoryNearModelChanged();
}

int PastVuModelController::GetZoomLevel() const
{
	return m_impl->screenObjectsModel->data({}, BaseModel::Roles::ZoomLevel).toInt();
}

void PastVuModelController::SetZoomLevel(int value)
{
	m_impl->screenObjectsModel->setData({}, value, BaseModel::Roles::ZoomLevel);
	emit ZoomLevelChanged();
}

Range PastVuModelController::GetTimelineRange() const
{
	return { m_impl->defaultTimelineRange.min, m_impl->defaultTimelineRange.max };
}

Range PastVuModelController::GetUserSelectedTimelineRange() const
{
	return m_impl->userSelectedTimelineRange;
}

void PastVuModelController::SetUserSelectedTimelineRange(const Range & range)
{
	m_impl->userSelectedTimelineRange = range;
	m_impl->settings.setValue(YEARS_FROM, range.min);
	m_impl->settings.setValue(YEARS_TO, range.max);
	emit UserSelectedTimelineRangeChanged(range);
}

/*!
    Toggles \l nearestObjectsOnly.
*/
void PastVuModelController::ToggleOnlyNearestObjects()
{
	SetNearestObjectsOnly(!GetNearestObjectsOnly());
	emit ModelChanged();
}

/*!
    Toggles \l historyNearModelType.
*/
void PastVuModelController::ToggleHistoryNearYouModel()
{
	SetHistoryNearModelType(!GetHistoryNearModelType());
	emit HistoryNearModelChanged();
}

/*!
    Forces a refresh of photo data for the current viewport.
*/
void PastVuModelController::ReloadItems()
{
	m_impl->baseModel->ReloadItems();
}

/*!
    Updates the visible map rectangle to \a viewport and requests photo data.
*/
void PastVuModelController::SetViewportCoordinates(const QGeoRectangle & viewport)
{
	m_impl->viewPort = viewport;
	emit m_impl->baseModel->UpdateCoords(viewport);
}

/*!
    \property PastVuModelController::nearestObjectsOnly

    Holds whether map markers use the nearest-objects cluster model.
*/

/*!
    \property PastVuModelController::historyNearModelType

    Holds the data-source selection for the "History near you" carousel.
*/

/*!
    \property PastVuModelController::zoomLevel

    Holds the map zoom level synchronized with the QML Map.
*/

/*!
    \property PastVuModelController::timelineRange

    Holds the read-only full year range supported by the application.
*/

/*!
    \property PastVuModelController::userSelectedTimelineRange

    Holds the user-adjustable year range applied by ScreenObjectsModel.
*/

/*!
    \fn void PastVuModelController::PositionPermissionGranted()

    Emitted after location permission is granted.
*/

/*!
    \fn void PastVuModelController::NearestObjectsOnlyChanged()

    Emitted when \l nearestObjectsOnly changes.
*/

/*!
    \fn void PastVuModelController::ModelChanged()

    Emitted when the active map model changes.
*/

/*!
    \fn void PastVuModelController::HistoryNearModelChanged()

    Emitted when \l historyNearModelType changes.
*/

/*!
    \fn void PastVuModelController::ZoomLevelChanged()

    Emitted when \l zoomLevel changes.
*/

/*!
    \fn void PastVuModelController::YearFromChanged()

    Emitted when the lower bound of the selected timeline changes.
*/

/*!
    \fn void PastVuModelController::YearToChanged()

    Emitted when the upper bound of the selected timeline changes.
*/

/*!
    \fn void PastVuModelController::UserSelectedTimelineRangeChanged(const Range &timeline)

    Emitted after the selected range changes to \a timeline.
*/

/*!
    \fn void PastVuModelController::loadingItems()

    Emitted when a photo fetch starts.
*/

/*!
    \fn void PastVuModelController::itemsLoaded()

    Emitted when a photo fetch completes.
*/
