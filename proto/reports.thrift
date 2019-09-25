include "base.thrift"
include "domain.thrift"

namespace java com.rbkmoney.reporter
namespace erlang reports

typedef base.Timestamp Timestamp
typedef base.InvalidRequest InvalidRequest
typedef domain.PartyID PartyID
typedef domain.ShopID ShopID
typedef domain.FileID FileID
typedef i64 ReportID
typedef string ReportType
typedef string URL

/**
* Ошибка превышения максимального размера блока данных, доступного для отправки клиенту.
* limit - текущий максимальный размер блока.
*/
exception DatasetTooBig {
    1: i32 limit
}

exception PartyNotFound {}
exception ShopNotFound {}
exception ReportNotFound {}
exception FileNotFound {}

struct ReportRequest {
    1: required PartyID party_id
    2: required ReportTimeRange time_range
    3: optional ShopID shop_id
}

/**
* Диапазон времени отчетов.
* from_time (inclusive) - начальное время.
* to_time (exclusive) - конечное время.
* Если from > to  - диапазон считается некорректным.
*/
struct ReportTimeRange {
    1: required Timestamp from_time
    2: required Timestamp to_time
}

/**
* Данные по отчету
* report_id - уникальный идентификатор отчета
* time_range - за какой период данный отчет
* report_type - тип отчета
* files - файлы данного отчета (к примеру сам отчет и его подпись)
*/
struct Report {
    1: required ReportID report_id
    2: required PartyID party_id
    3: required ReportTimeRange time_range
    4: required Timestamp created_at
    5: required ReportType report_type
    6: required ReportStatus status
    7: optional list<FileMeta> files
    8: optional ShopID shop_id
}

/**
* Статусы отчета
*/
enum ReportStatus {
    // в обработке
    pending
    // создан
    created
    // отменен
    canceled
}

/**
* Данные по файлу
* file_id - уникальный идентификатор файла
* signatures - сигнатуры файла (md5, sha256)
*/
struct FileMeta {
    1: required FileID file_id
    2: required string filename
    3: required Signature signature
}

/**
* Cигнатуры файла
*/
struct Signature {
    1: required string md5
    2: required string sha256
}

service Reporting {

  /**
  * Создать отчет с указанным типом по магазину за указанный промежуток времени
  * Возвращает идентификатор отчета
  *
  * PartyNotFound, если party не найден
  * ShopNotFound, если shop не найден
  * InvalidRequest, если промежуток времени некорректен
  */
  ReportID CreateReport(1: ReportRequest request, 2: ReportType report_type) throws (1: PartyNotFound ex1, 2: ShopNotFound ex2, 3: InvalidRequest ex3)

  /**
  * Получить список отчетов по магазину за указанный промежуток времени с фильтрацией по типу
  * В случае если список report_types пустой, фильтрации по типу не будет
  * Возвращает список отчетов или пустой список, если отчеты по магазину не найдены
  *
  * InvalidRequest, если промежуток времени некорректен
  * DatasetTooBig, если размер списка превышает допустимый лимит
  */
  list<Report> GetReports(1: ReportRequest request, 2: list<ReportType> report_types) throws (1: DatasetTooBig ex1, 2: InvalidRequest ex2)

  /**
  * Запрос на получение отчета
  *
  * ReportNotFound, если отчет не найден
  */
  Report GetReport(1: ReportID report_id) throws (1: ReportNotFound ex1)

  /**
  * Запрос на отмену отчета
  *
  * ReportNotFound, если отчет не найден
  */
  void cancelReport(1: ReportID report_id) throws (1: ReportNotFound ex1)

  /**
  * Сгенерировать ссылку на файл
  * file_id - идентификатор файла
  * expires_at - время до которого ссылка будет считаться действительной
  * Возвращает presigned url
  *
  * FileNotFound, если файл не найден
  * InvalidRequest, если expires_at некорректен
  */
  URL GeneratePresignedUrl(1: FileID file_id, 2: Timestamp expires_at) throws (1: FileNotFound ex1, 2: InvalidRequest ex2)

}
