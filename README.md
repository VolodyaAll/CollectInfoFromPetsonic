# CollectInfoFromPetsonic
***
## Назначение
Скрипт собирает информацию о продуктах( название, весовка, цена, ссылка на фото, актуальность ) с сайта petsonic.com
***
## Запуск
git clone git@github.com:VolodyaAll/CollectInfoFromPetsonic.git

bundle install

ruby app.rb -u url_категории -f имя_результирующего_файла.scv

При запуске скрипта без параметров идёт сбор информации в категории https://www.petsonic.com/snacks-huesos-para-perros/, результаты записываются в файл results.scv

