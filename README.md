# CollectInfoFromPetsonic
Тестовое задание от Profitero
***
## Назначение
Скрипт собирает информацию о продуктах( название, весовка, цена, ссылка на фото, актуальность ) с сайта petsonic.com
***
## Запуск
git clone git@github.com:VolodyaAll/CollectInfoFromPetsonic.git

bundle install

ruby app.rb -u url_категории -f результирующbq_файл.csv

При запуске скрипта без параметров идёт сбор информации в категории https://www.petsonic.com/snacks-huesos-para-perros/, результаты записываются в файл results.csv
