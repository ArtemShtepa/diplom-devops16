# Дипломный проект

## Постановка задачи

## Состав инфраструктуры

[Схема инфраструктуры](https://viewer.diagrams.net/?tags=%7B%7D&target=blank&highlight=0000ff&layers=1&nav=1&title=%D0%A1%D1%85%D0%B5%D0%BC%D0%B0%20%D0%B8%D0%BD%D1%84%D1%80%D0%B0%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%82%D1%83%D1%80%D1%8B.drawio#R7ZxLb6s4FMc%2FTaSZRSvekGXT50hzpUpd3NFsKgecxApgZJyGO59%2BbMAhwU4Kt5CENF1QcrB5nP%2FP9rGxGZn3UfZMQLL4gQMYjgwtyEbmw8gwdG3ssX%2Fc8quweEZpmBMUlIkqwxv6D4qcpXWFApjuJKQYhxQlu0YfxzH06Y4NEILXu8lmONy9agLmUDK8%2BSCUrT9RQBfiKdzK%2FgLRfCGurDvj4kgEROLySdIFCPB6y2Q%2Bjsx7gjEt9qLsHobcecIvRb6nPUc3N0ZgTJtkSPyxNn0hS3f6L7n5ESfmP%2BbLjbi5DxCuyicu75b%2BEi4geBUHkJ9FH5mT9QJR%2BJYAnx9dM9GZbUGjsDws31V5ox%2BQUJhtmcq7fIY4gpT8YknKo%2BbYvrWLTCU04i7XlQKWVtoWW97fJASl6vPNySvHsJ3SNy38pI8H4SdH4Sj9uI7yOnZUCKYwfMUpogjHzOYzh0HCDnBHIVZQ%2F64liFAQ8CtNQIjmyhx35YFNyg7EEDn2E2valpBrWwrH7k0KSYlXgjN2Xidk155MCdub8723txeWbvSgjcY6307Yvj7y9Hxr5BYv3z7m2wf5DH9MQcrd%2F6ek9T6VpphSHLGs6RJSn7tI45KlSVGJz1DGAdkGoa4exZyUlBK8hPc4xEzhhxjHSuXxioYoZslEI8EvxirkhN9llM1523XrI0pQdptwJ72nkHzkWbtgw6oXVFvBh%2Buo8Bj3RYchl1MOgFdKXElv5%2FuasG8scrkentbzEE87qgAsUY6FxKZCYk8lsWv3JLHcZjGnMB%2FyjK8hYO6TC%2FJHdLNcTeGN3rwob6rR35a3OsMhhUnhslYC%2BziKQBy8b%2BioNychnNFuANCl5lgfKxCwlaXc6asNkOO75gyYl1CdSwR0Uda9utSmdXqp5fa%2BudRGc6lLoX5X54qU%2FqXeGzt2wYBTZ0ARfB8bAblR%2F4nJEpIDyluXUdFnMAZJUoVt%2FdXzcjSnKvuOLLs37kt2s73sziXU7XXRO1DXsaVOtXdqea328tqXUJ9%2FVqa7rM4dKXpz3BPLbkuyPyPK1FPLHgEUt4naz7dUBzBdsnO%2Fr%2BG0G21dKVpzTYW2R%2B1%2B646sLgEzEANZ3r%2FiWbjKHiYHhG8Rv31n4W3DEJYTSu9K0vM626c8Z6IeopsjGvKSr5EVc%2BSemj8n4SI6bcHC77ZZl4M2ZY9NUb%2F3NwAnR22ScjAO7vhLLO7HEKQp8nN3A0Jl85ZM1QC7dsh9KV4RHx4itUjHrjeH9NCjFOlgsPMuTRZjy9W24q2EsBEYAoo%2Bdt%2FAqfxfXuEVI%2FZkB96LWPUx9uLJy3zG1juz2qksRaxfO1XhHOlUORKbR%2F8CJXLwd3aU2A0x0a%2BY9IaJHCyeHSZNKXGumPSGiRx1nh0mbkNOxldMesNEjlAHi4l4A3LlpAdOGkz2GAwn1%2BikN04s%2BdVUM05OGq26VyB6A6Jd37ccUghAuthMG%2BsDjcYh6tm3KW53aNSnCvaNRrsObys08hcIE%2BAv57ldjFiNDNNhf09PX6JnfDHwDLheade%2FOVK90piMawjSHxntujSfkMHtr4BSSOLcYmjmZhxcLBMwTkGQcSWoN4LadXaGSpB5Jag3ghosIrkAgqwrQX0RJO58mASJyPcCKqHh9q%2FsdmMxvSC0vx%2F2lP99jTKrKWVn3xEbMGXGpVNmXAxlA24OOx1GPHpz2Hi48doc9odQp8ONR0eocVt39kNLA0ao3dybc0OocUN29ggNuCFTjVuXU3zFDN98eba7sw6%2FWKtfLN2fWOLQ9tJ9tjVz%2B9NWlkfF8n5DuxNXZE9QXbQOMoUZ3QVWOft3hsLwswnBexeHqb4I0RD3Fl%2FPkGug4ucWvp4KX3M%2FqV%2BaD2yrRqiPzMDkezHgatKSbcVir%2BNSoBplPjIF99%2Bdgs03c7qngP2sPvlUNB%2FVh7PMx%2F8B)

Исходный код схемы приведён в файле [infrastructure.drawio](./schema_source/infrastructure.drawio)

## Приложение

Простейший API сервер на языке **GoLang**, обрабатывающий HTTP запросы:
  - По **url** `/task/<id>` выводит в лог число `<id>`. В ответном JSON блоке результат преобразования `<id>` в число
  - По **url** `/wait` замораживает выполнение приложения от 1 до 5 секунд. В ответном JSON блоке включается время начала и окончания заморозки в формате ISO и Unix Timestamp
  - На остальные **url** в ответный JSON блок включается путь и HTTP метод запроса

Приложение, по умолчанию, принимает соединения со всех адресов по порту **8080** (`0.0.0.0:8080`).

Изменить прослушиваемый порт и принимамые адреса можно
параметром запуска `-addr` (например, `apiserver --addr 127.0.0.1:80`),
либо переменной окружения `API_BIND` (например, `export API_BIND=:8090`)

[Исходный код](./app_source/apiserver.go)
