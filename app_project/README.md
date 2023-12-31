# Проект API Сервера

Написан на языке [Go](https://go.dev/learn/)

## Запуск

По умолчанию, сервер прослушивает порт `8080` и отвечает на запросы со всех IP адресов (`0.0.0.0`).  
Изменить разрешённые адреса и используемый порт можно:
  - Переменной окружения `API_BIND`, например: `export API_BIND=0.0.0.0:8111`
  - Параметром запуска `-addr`, например: `apiserver -addr=0.0.0.0:8111`

## Функционирование

Приложение обрабатывает входящие с разрешённых адресов **HTTP** запросы.  
В качестве ответа формируется **JSON** блок с данными в зависимости от запрашиваемого **url**.

## Идентификация приложения

При запуске приложения генерируется уникальный **UUID** идентификатор, который не меняется на протяжении всей работы приложения, что позволяет идентифицировать конкретный экземпляр приложения.
Уникальный **UUID** выдаётся на запрос `/uuid`, при этом в ответ дополнительно включается версия приложения.

Версия приложения задана в исходном коде параметром `Version`, имеющим значение по умолчанию `Unknown`.
Версия может быть изменена на этапе сборки приложения передачей компилятору её значения вместо `$VER` в параметре `-ldflags="-X 'main.Version=$VER'"`.

## Доступные команды

- `/uuid` - Вывод информации по текущему экземпляру сервера. Формирует JSON блок с полями Version - текущая версия и UUId - уникальный идентификатор экземпляра
- `/task` - Имитация управления задачами. В ответ формирует JSON блок с переданным номером задачи в поле `id`
- `/wait` - Приостанавливает исполнение запросов на время от 1 до 5 секунд. В ответ формирует JSON блок с параметрами времени остановки (Start, UnixStart) и возобновления (Finish, UnixFinish) работы сервера
- `/ip` - Вывод присвоенных ОС IP адресов. Формирует JSON блок списка IP адресов.
- `/` (Все остальные запросы) - Формирует JSON блок с полями Path - запрашиваемый url и method - используемый метод HTTP запроса
