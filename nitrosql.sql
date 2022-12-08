CREATE TABLE `nitro_vehicles` (
	`plate` longtext NOT NULL,
	`amount` int(11) NOT NULL
);

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('nitrocannister', 'Nitro canister', 1, 0, 1),
('wrench', 'Wrench', 1, 0, 1);