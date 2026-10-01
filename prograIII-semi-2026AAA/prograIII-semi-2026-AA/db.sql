-- =====================================================================
-- Base de datos: db_sistema_impuestos
-- Sistema de Impuesto a las Actividades Económicas
-- Importar en phpMyAdmin (pestaña "Importar") o pegar en la pestaña "SQL".
-- OJO: borra y vuelve a crear las tablas (DROP TABLE).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `db_sistema_impuestos`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `db_sistema_impuestos`;

DROP TABLE IF EXISTS `bitacora`;
DROP TABLE IF EXISTS `periodos`;
DROP TABLE IF EXISTS `tarifas`;
DROP TABLE IF EXISTS `productos`;
DROP TABLE IF EXISTS `clientes`;

-- ---------------------------------------------------------------- clientes
CREATE TABLE `clientes` (
  `idCliente` int(10) NOT NULL AUTO_INCREMENT,
  `codigo`    char(10)  NOT NULL,
  `nombre`    char(100) NOT NULL,
  `direccion` char(150) NOT NULL,
  `telefono`  char(10)  NOT NULL,
  `email`     char(150) NOT NULL,
  `tipo`      char(100) NOT NULL DEFAULT 'particular',   -- 'particular' | 'empresa'
  PRIMARY KEY (`idCliente`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------------- productos
CREATE TABLE `productos` (
  `idProducto` int(10) NOT NULL AUTO_INCREMENT,
  `codigo`     char(10)  NOT NULL,
  `nombre`     char(100) NOT NULL,
  PRIMARY KEY (`idProducto`),
  UNIQUE KEY `uk_producto_codigo` (`codigo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------------------------------------------- tarifas
CREATE TABLE `tarifas` (
  `idTarifa`      int(10) NOT NULL AUTO_INCREMENT,
  `idProducto`    int(10) NOT NULL,
  `desde`         decimal(14,2) NOT NULL,          -- balance mínimo del rango
  `hasta`         decimal(14,2) NOT NULL,          -- balance máximo del rango
  `precio_base`   decimal(14,6) NOT NULL DEFAULT 0,
  `adicional`     decimal(14,6) NOT NULL DEFAULT 0, -- por cada bloque de mil
  `porcentaje`    decimal(14,6) NOT NULL DEFAULT 0, -- si > 0 se usa Balance x % / 100
  `vigente_desde` date NOT NULL,
  `vigente_hasta` date DEFAULT NULL,
  `version`       int(10) NOT NULL DEFAULT 1,
  PRIMARY KEY (`idTarifa`),
  KEY `idx_tarifa_producto` (`idProducto`),
  CONSTRAINT `fk_tarifa_producto` FOREIGN KEY (`idProducto`) REFERENCES `productos` (`idProducto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------------------------------------------- periodos
CREATE TABLE `periodos` (
  `idPeriodo`      int(10) NOT NULL AUTO_INCREMENT,
  `idCliente`      int(10) NOT NULL,
  `idProducto`     int(10) NOT NULL,
  `desde`          date NOT NULL,
  `hasta`          date NOT NULL,                    -- intervalo [desde, hasta)
  `monto`          decimal(14,2) NOT NULL,           -- balance
  `cantidad`       decimal(10,2) NOT NULL DEFAULT 1.00,
  `precio`         decimal(14,6) NOT NULL,
  `subtotal`       decimal(14,2) NOT NULL,
  `idTarifa`       int(10) DEFAULT NULL,
  `tarifa_detalle` longtext DEFAULT NULL,            -- JSON con la "foto" del cálculo
  `formula_version` char(20) NOT NULL DEFAULT 'v2_bloques',
  `fecha_calculo`  datetime DEFAULT NULL,
  `facturado`      tinyint(1) NOT NULL DEFAULT 0,
  `creado_por`     char(50) DEFAULT NULL,
  PRIMARY KEY (`idPeriodo`),
  KEY `idx_periodo_cliente` (`idCliente`,`idProducto`,`desde`),
  CONSTRAINT `fk_periodo_cliente`  FOREIGN KEY (`idCliente`)  REFERENCES `clientes`  (`idCliente`),
  CONSTRAINT `fk_periodo_producto` FOREIGN KEY (`idProducto`) REFERENCES `productos` (`idProducto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ----------------------------------------------------------------- bitacora
CREATE TABLE `bitacora` (
  `idBitacora` int(10) NOT NULL AUTO_INCREMENT,
  `idPeriodo`  int(10) DEFAULT NULL,
  `accion`     char(20) NOT NULL,                    -- 'CREACION' | 'CIERRE'
  `usuario`    char(50) NOT NULL,
  `detalle`    text DEFAULT NULL,
  `fecha`      datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`idBitacora`),
  KEY `idx_bitacora_periodo` (`idPeriodo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =====================================================================
-- DATOS  (segun el documento "Requerimiento Impuesto Actividades Economicas")
-- =====================================================================

-- Seccion 18.1: la tabla tarifaria aparece bajo 11802 (Industria) y los periodos
-- historicos bajo 11801 (Comercio). Aun no esta confirmado si comparten tabla.
-- Aqui se cargan las MISMAS tarifas como filas separadas para cada producto
-- (cada tarifa pertenece expresamente a su producto, CA 11).
INSERT INTO `productos` (`idProducto`, `codigo`, `nombre`) VALUES
(1, '11801', 'Impuesto a las Actividades Economicas Comercio'),
(2, '11802', 'Impuesto a las Actividades Economicas Industria');

-- >>> CAMBIA ESTOS CLIENTES POR LOS TUYOS <<<
INSERT INTO `clientes` (`idCliente`, `codigo`, `nombre`, `direccion`, `telefono`, `email`, `tipo`) VALUES
(1, '001', 'Tu Nombre Aqui',        'Tu direccion', '0000-0000', 'tucorreo@ejemplo.com', 'particular'),
(2, '002', 'Mi Empresa Ejemplo SA', 'Tu direccion', '0000-0000', 'empresa@ejemplo.com',  'empresa');

-- Tabla tarifaria de la seccion 8 (producto 1 = Comercio).
-- OJO: NO existe el rango 6,000.01 a 8,000.00 (seccion 18.2 / CA 10):
-- esos balances deben rechazarse, no se inventa una tarifa.
INSERT INTO `tarifas`
  (`idTarifa`, `idProducto`, `desde`, `hasta`, `precio_base`, `adicional`, `porcentaje`, `vigente_desde`, `vigente_hasta`, `version`) VALUES
(1,  1,       0.01,        500.00,   1.50, 0.00, 0, '2020-01-01', NULL, 1),
(2,  1,     500.01,       1000.00,   1.50, 3.00, 0, '2020-01-01', NULL, 1),
(3,  1,    1000.01,       2000.00,   3.00, 3.00, 0, '2020-01-01', NULL, 1),
(4,  1,    2000.01,       3000.00,   6.00, 3.00, 0, '2020-01-01', NULL, 1),
(5,  1,    3000.01,       6000.00,   9.00, 2.00, 0, '2020-01-01', NULL, 1),
(6,  1,    8000.01,      18000.00,  15.00, 2.00, 0, '2020-01-01', NULL, 1),
(7,  1,   18000.01,      30000.00,  39.00, 2.00, 0, '2020-01-01', NULL, 1),
(8,  1,   30000.01,      60000.00,  63.00, 1.00, 0, '2020-01-01', NULL, 1),
(9,  1,   60000.01,     100000.00,  93.00, 0.80, 0, '2020-01-01', NULL, 1),
(10, 1,  100000.01,     200000.00, 125.00, 0.70, 0, '2020-01-01', NULL, 1),
(11, 1,  200000.01,     300000.00, 195.00, 0.60, 0, '2020-01-01', NULL, 1),
(12, 1,  300000.01,     400000.00, 255.00, 0.45, 0, '2020-01-01', NULL, 1),
(13, 1,  400000.01,     500000.00, 300.00, 0.40, 0, '2020-01-01', NULL, 1),
(14, 1,  500000.01,    1000000.00, 340.00, 0.30, 0, '2020-01-01', NULL, 1),
(15, 1, 1000000.01,  99999999.99, 490.00, 0.18, 0, '2020-01-01', NULL, 1);

-- Mismas tarifas para Industria (producto 2), como filas propias.
INSERT INTO `tarifas`
  (`idProducto`, `desde`, `hasta`, `precio_base`, `adicional`, `porcentaje`, `vigente_desde`, `vigente_hasta`, `version`)
SELECT 2, `desde`, `hasta`, `precio_base`, `adicional`, `porcentaje`, `vigente_desde`, `vigente_hasta`, `version`
FROM `tarifas` WHERE `idProducto` = 1 ORDER BY `idTarifa`;

-- Periodos historicos de la seccion 7 (empresa 2, producto 11801 Comercio).
-- 2022: balance 700.00 con la formula proporcional anterior = 2.10 (seccion 12).
-- Los anteriores a 2026 ya fueron facturados (facturado = 1): no se recalculan.
INSERT INTO `periodos`
  (`idPeriodo`, `idCliente`, `idProducto`, `desde`, `hasta`, `monto`, `cantidad`, `precio`, `subtotal`,
   `idTarifa`, `tarifa_detalle`, `formula_version`, `fecha_calculo`, `facturado`, `creado_por`) VALUES
(1, 2, 1, '2022-01-01', '2023-01-01', 700.00, 1.00, 2.100000, 2.10, 2,
 '{"balance": "700.00", "rango_desde": "500.01", "rango_hasta": "1000.00", "precio_base": "1.50", "adicional": "3.00", "porcentaje": "0", "formula": "v1_proporcional", "version_tarifa": 1, "expresion": "1.50 + ((700.00 - 500.00) / 1,000 x 3.00) = 2.10"}',
 'v1_proporcional', '2022-01-01 00:00:00', 1, 'admin'),
(2, 2, 1, '2023-01-01', '2024-01-01', 545.00, 1.00, 4.500000, 4.50, 2,
 '{"balance": "545.00", "rango_desde": "500.01", "rango_hasta": "1000.00", "precio_base": "1.50", "excedente": "44.99", "bloques": "1", "adicional": "3.00", "porcentaje": "0", "formula": "v2_bloques", "version_tarifa": 1, "expresion": "1.50 + (1 x 3.00) = 4.50"}',
 'v2_bloques', '2023-01-01 00:00:00', 1, 'admin'),
(3, 2, 1, '2024-01-01', '2025-01-01', 550.00, 1.00, 4.500000, 4.50, 2,
 '{"balance": "550.00", "rango_desde": "500.01", "rango_hasta": "1000.00", "precio_base": "1.50", "excedente": "49.99", "bloques": "1", "adicional": "3.00", "porcentaje": "0", "formula": "v2_bloques", "version_tarifa": 1, "expresion": "1.50 + (1 x 3.00) = 4.50"}',
 'v2_bloques', '2024-01-01 00:00:00', 1, 'admin'),
(4, 2, 1, '2025-01-01', '2026-01-01', 550.00, 1.00, 4.500000, 4.50, 2,
 '{"balance": "550.00", "rango_desde": "500.01", "rango_hasta": "1000.00", "precio_base": "1.50", "excedente": "49.99", "bloques": "1", "adicional": "3.00", "porcentaje": "0", "formula": "v2_bloques", "version_tarifa": 1, "expresion": "1.50 + (1 x 3.00) = 4.50"}',
 'v2_bloques', '2025-01-01 00:00:00', 1, 'admin'),
(5, 2, 1, '2026-01-01', '2027-01-01', 550.00, 1.00, 4.500000, 4.50, 2,
 '{"balance": "550.00", "rango_desde": "500.01", "rango_hasta": "1000.00", "precio_base": "1.50", "excedente": "49.99", "bloques": "1", "adicional": "3.00", "porcentaje": "0", "formula": "v2_bloques", "version_tarifa": 1, "expresion": "1.50 + (1 x 3.00) = 4.50"}',
 'v2_bloques', '2026-01-01 00:00:00', 0, 'admin');

INSERT INTO `bitacora` (`idPeriodo`, `accion`, `usuario`, `detalle`) VALUES
(1, 'CREACION', 'admin', 'Periodo historico 2022: balance 700.00, formula v1_proporcional, precio 2.10'),
(2, 'CREACION', 'admin', 'Periodo 2023: balance 545.00, formula v2_bloques, precio 4.50'),
(3, 'CREACION', 'admin', 'Periodo 2024: balance 550.00, formula v2_bloques, precio 4.50'),
(4, 'CREACION', 'admin', 'Periodo 2025: balance 550.00, formula v2_bloques, precio 4.50'),
(5, 'CREACION', 'admin', 'Periodo 2026: balance 550.00, formula v2_bloques, precio 4.50');
