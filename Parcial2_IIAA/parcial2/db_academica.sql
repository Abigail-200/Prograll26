-- ------------------------------------------------------------
-- Parcial II - Programacion Computacional III
-- Base de datos: db_academica
-- Importar desde phpMyAdmin (pestaña "Importar") o pegar en la pestaña "SQL".
-- Si su codigo de estudiante no es usss016325, cambie el nombre de la tabla
-- (buscar y reemplazar "usss016325") aqui y en crud_usuarios_usss016325.py
-- ------------------------------------------------------------

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Database: `db_academica`
--
CREATE DATABASE IF NOT EXISTS `db_academica` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `db_academica`;

-- --------------------------------------------------------

--
-- Table structure for table `usuarios_usss016325`
--

CREATE TABLE `usuarios_usss016325` (
  `idUsuario` int(10) NOT NULL,
  `usuario` char(35) NOT NULL,
  `clave` char(35) NOT NULL,
  `nombre` char(85) NOT NULL,
  `direccion` char(100) NOT NULL,
  `telefono` char(9) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `usuarios_usss016325`
-- (la clave se guarda como MD5, 32 caracteres, cabe en char(35))
-- Usuario inicial para poder entrar al login:  admin / admin123
--

INSERT INTO `usuarios_usss016325` (`idUsuario`, `usuario`, `clave`, `nombre`, `direccion`, `telefono`) VALUES
(1, 'admin', MD5('admin123'), 'Administrador', 'Usulutan', '7777-7777');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `usuarios_usss016325`
--
ALTER TABLE `usuarios_usss016325`
  ADD PRIMARY KEY (`idUsuario`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `usuarios_usss016325`
--
ALTER TABLE `usuarios_usss016325`
  MODIFY `idUsuario` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;
