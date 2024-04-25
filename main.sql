USE lesson_4;

/* Задача 1
Создайте таблицу users_old, аналогичную таблице users. 
Создайте процедуру, с помощью которой можно переместить любого (одного) пользователя из таблицы users в таблицу users_old. 
(использование транзакции с выбором commit или rollback – обязательно).
*/
-- создание таблицы users_old
DROP TABLE IF EXISTS ysers_old;
CREATE TABLE users_old (
	id SERIAL PRIMARY KEY,
	firstname VARCHAR(50) COMMENT 'Имя',
	lastname VARCHAR(50) COMMENT 'Фамилия',
	email VARCHAR(120) UNIQUE
	);

-- создание процедуры перемещения любого (одного) пользователя из таблицы users в таблицу users_old.
DROP PROCEDURE IF EXISTS sp_moving_user;
DELIMITER //
CREATE PROCEDURE sp_moving_user(choice_user_id BIGINT, OUT show_result VARCHAR(100))
BEGIN	
	DECLARE `_rollback` BIT DEFAULT b'0';
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
 		SET `_rollback` = b'1';
	END;
	-- проверка на наличие пользователя с id = choice_user_id в таблице users
	-- если пользователь с id = choice_user_id существует
	IF EXISTS (SELECT * FROM users WHERE id = choice_user_id) THEN
		START TRANSACTION; 
		INSERT INTO users_old 
		SELECT * FROM users 
		WHERE id = choice_user_id;
		-- выводим ошибку если пытаемся добавить пользователя который уже есть в таблице users_old
		IF `_rollback` THEN
			SET show_result = 'Возникла ошибка, проверьте корректность введенных данных';
			ROLLBACK; 
		ELSE
			SET show_result = 'Данные пользователя перенесы в таблицу users_old';
			COMMIT;
		END IF;
	-- если пользователя с id = choice_user_id не существует в таблице users
	-- выводим текст ошибки
	ELSE
		SET show_result = CONCAT('Пользователя с id: ', choice_user_id, ' нет в таблице users');
	END IF;
END//
DELIMITER ;

-- вызываем процедуру
CALL sp_moving_user(5, @show_result);
SELECT @show_result;



/* Задача 2
Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", 
с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
*/
DROP FUNCTION IF EXISTS hello;
DELIMITER //
CREATE FUNCTION hello()
RETURNS VARCHAR(20) READS SQL DATA
BEGIN
DECLARE result VARCHAR(20);
	SELECT CASE
	 WHEN CURRENT_TIME BETWEEN  '06:00:00' AND '12:00:00' 
 	 	THEN  'Доброе утро'
 	 WHEN CURRENT_TIME BETWEEN  '12:00:00' AND '18:00:00'
 	 	THEN  'Добрый день'
	 WHEN CURRENT_TIME BETWEEN  '18:00:00' AND '00:00:00'
	 	THEN  'Добрый вечер'
	 ELSE  'Доброй ночи'	
	END INTO result;
	RETURN result;
END//
DELIMITER ;

-- вызов функции hello
SELECT hello();


/* Задача 3
 (по желанию)* Создайте таблицу logs типа Archive. 
 Пусть при каждом создании записи в таблицах users, 
 communities и messages в таблицу logs помещается время и дата создания записи, 
 название таблицы, идентификатор первичного ключа.
 */

-- создание таблицы logs типа ARCHIVE
DROP TABLE IF EXISTS logs;
CREATE TABLE logs (
	name_table VARCHAR(20),
	date_time DATETIME,
	id_in_table  BIGINT)
	ENGINE = ARCHIVE;

-- создание триггера для отслеживания изменений в таблице users
DROP TRIGGER IF EXISTS tracking_changes_users;
DELIMITER //
CREATE TRIGGER tracking_changes_users AFTER INSERT ON users
FOR EACH ROW 
BEGIN 
	INSERT INTO logs (name_table, date_time, id_in_table)
	VALUES (
		'users',
		NOW(),
		(SELECT max(id) FROM users));
END//
DELIMITER ;

-- проверка работоспособности триггера tracking_changes_users
INSERT INTO users (firstname, lastname, email)
VALUES('nikita1', 'mikhailov1', 'dog@mail1.ru');



-- создание триггера для отслеживания изменений в таблице communities
DROP TRIGGER IF EXISTS tracking_changes_communities;
DELIMITER //
CREATE TRIGGER tracking_changes_communities AFTER INSERT ON communities
FOR EACH ROW 
BEGIN 
	INSERT INTO logs (name_table, date_time, id_in_table)
	VALUES (
		'communities',
		NOW(),
		(SELECT max(id) FROM communities));
END//
DELIMITER ;

-- проверка работоспособности триггера tracking_changes_communities
INSERT INTO communities (name)
VALUES('communities');



-- создание триггера для отслеживания изменений в таблице messages
DROP TRIGGER IF EXISTS tracking_changes_messages;
DELIMITER //
CREATE TRIGGER tracking_changes_messages AFTER INSERT ON messages
FOR EACH ROW 
BEGIN 
	INSERT INTO logs (name_table, date_time, id_in_table)
	VALUES (
		'messages',
		NOW(),
		(SELECT max(id) FROM messages));
END//
DELIMITER ;

-- проверка работоспособности триггера tracking_changes_messages
INSERT INTO messages (from_user_id, to_user_id, body)
VALUES(1, 2, 'проверка работоспособности триггера');