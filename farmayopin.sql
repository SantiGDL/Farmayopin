-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 23-09-2026 a las 15:50:36
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `farmayopin`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Carritos`
--

CREATE TABLE `Carritos` (
  `Id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `Carritos`
--

INSERT INTO `Carritos` (`Id`) VALUES
(1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Compras`
--

CREATE TABLE `Compras` (
  `Id` int(11) NOT NULL,
  `EstadoCompra` int(11) NOT NULL,
  `FechaCompra` datetime(6) NOT NULL,
  `PrecioTotal` decimal(65,30) NOT NULL,
  `UsuarioAsociadoId` int(11) NOT NULL,
  `CarritoAsociadoId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `Compras`
--

INSERT INTO `Compras` (`Id`, `EstadoCompra`, `FechaCompra`, `PrecioTotal`, `UsuarioAsociadoId`, `CarritoAsociadoId`) VALUES
(1, 1, '2026-09-17 19:48:49.715223', 730.000000000000000000000000000000, 1, 1),
(2, 1, '2026-09-17 19:49:32.889216', 2030.000000000000000000000000000000, 1, 1),
(3, 1, '2026-09-23 00:18:47.186724', 1350.000000000000000000000000000000, 1, 1),
(4, 1, '2026-09-23 00:19:13.283629', 1400.000000000000000000000000000000, 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `LineasDeCarrito`
--

CREATE TABLE `LineasDeCarrito` (
  `Id` int(11) NOT NULL,
  `CantidadProducto` int(11) NOT NULL,
  `CarritoId` int(11) NOT NULL,
  `ProductoId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `LineasDeCompra`
--

CREATE TABLE `LineasDeCompra` (
  `Id` int(11) NOT NULL,
  `CantidadProducto` int(11) NOT NULL,
  `PrecioUnitario` decimal(65,30) NOT NULL,
  `NombreProducto` longtext NOT NULL,
  `ProductoAsociadoId` int(11) NOT NULL,
  `CompraAsociadaId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `LineasDeCompra`
--

INSERT INTO `LineasDeCompra` (`Id`, `CantidadProducto`, `PrecioUnitario`, `NombreProducto`, `ProductoAsociadoId`, `CompraAsociadaId`) VALUES
(1, 1, 30.000000000000000000000000000000, 'Jabon Buldog', 4, 1),
(2, 1, 500.000000000000000000000000000000, 'Parasetamol', 1, 2),
(3, 1, 500.000000000000000000000000000000, 'Creama Corporal Super Pro', 2, 2),
(4, 1, 300.000000000000000000000000000000, 'Shampoo', 3, 2),
(5, 1, 30.000000000000000000000000000000, 'Jabon Buldog', 4, 2),
(6, 1, 200.000000000000000000000000000000, 'Chocolate', 5, 3),
(7, 1, 250.000000000000000000000000000000, 'Perifar Flex', 7, 3),
(8, 1, 200.000000000000000000000000000000, 'Desodorante', 8, 3),
(9, 1, 500.000000000000000000000000000000, 'Creama Corporal Super Pro', 2, 4),
(10, 1, 200.000000000000000000000000000000, 'Chocolate', 5, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Productos`
--

CREATE TABLE `Productos` (
  `Id` int(11) NOT NULL,
  `Nombre` longtext NOT NULL,
  `Detalle` longtext NOT NULL,
  `Precio` decimal(65,30) NOT NULL,
  `FotoUrl` longtext DEFAULT NULL,
  `Stock` int(11) NOT NULL,
  `Categoria` int(11) DEFAULT NULL,
  `Codigo` longtext NOT NULL,
  `Unidad` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `Productos`
--

INSERT INTO `Productos` (`Id`, `Nombre`, `Detalle`, `Precio`, `FotoUrl`, `Stock`, `Categoria`, `Codigo`, `Unidad`) VALUES
(1, 'Parasetamol', 'Dolorcinio de Cabeza', 500.000000000000000000000000000000, '/Imagenes/Productos/Paracetamol.jpeg', 199, NULL, '', NULL),
(2, 'Creama Corporal Super Pro', 'Para Humectarse', 500.000000000000000000000000000000, '/Imagenes/Productos/CreamaCorporal.jpeg', 198, NULL, '1122', NULL),
(3, 'Shampoo', 'Lavado Profesional', 300.000000000000000000000000000000, '/Imagenes/Productos/Shampoo.jpeg', 249, NULL, '112256', NULL),
(4, 'Jabon Buldog', 'Lavado ', 30.000000000000000000000000000000, '/Imagenes/Productos/JabonBuldog.jpeg', 248, NULL, '112', NULL),
(5, 'Chocolate', '100% Cacao', 200.000000000000000000000000000000, '/Imagenes/Productos/1ef63a0f2d084003ac1e460219d93698.jpg', 198, NULL, '11AB', NULL),
(6, 'Perifar', 'Dolor Cabeza Fuera', 200.000000000000000000000000000000, 'assets/imagenes/producto_default.png', 200, NULL, '11BB', NULL),
(7, 'Perifar Flex', 'Dolor Cabeza Fuera Flexeado', 250.000000000000000000000000000000, '/Imagenes/Productos/PerifarFlex.jpeg', 199, NULL, '11BBSITA', NULL),
(8, 'Desodorante', 'Desodorante Masculino', 200.000000000000000000000000000000, '/Imagenes/Productos/5f663100033d4953b1e5deeaf6f4cee5.jpg', 19, 1, '11ABBSD', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `Usuarios`
--

CREATE TABLE `Usuarios` (
  `Id` int(11) NOT NULL,
  `Rol` varchar(20) NOT NULL,
  `Nombre` longtext NOT NULL,
  `Correo` varchar(255) NOT NULL,
  `Pass` longtext NOT NULL,
  `Imagen` longtext NOT NULL,
  `CarritoAsociadoId` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `Usuarios`
--

INSERT INTO `Usuarios` (`Id`, `Rol`, `Nombre`, `Correo`, `Pass`, `Imagen`, `CarritoAsociadoId`) VALUES
(1, 'CLIENTE', 'Santiago', 'santiago@gmail.com', '1234', '', 1),
(2, 'ADMIN', 'Goku', 'goku@gmail.com', 'goku123', '', NULL),
(3, 'CLIENTE', 'santiS', 'santiS@gmail.com', '123456', '', NULL),
(4, 'CLIENTE', 'Usuario1', 'usuario1@gmail.com', 'usuario1123', '', NULL),
(5, 'CLIENTE', 'usuario 2', 'usuario2@gmail.com', '123456', '', NULL),
(6, 'CLIENTE', 'usuario3', 'usuario3@gmail.com', '123456', '', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `__EFMigrationsHistory`
--

CREATE TABLE `__EFMigrationsHistory` (
  `MigrationId` varchar(150) NOT NULL,
  `ProductVersion` varchar(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `__EFMigrationsHistory`
--

INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`) VALUES
('20260914120045_Inicial', '9.0.20'),
('20260915075855_AgregarCodigoCategoriaYUnidadProducto', '9.0.20'),
('20260915120000_GuardarRolUsuarioComoTexto', '9.0.20');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `Carritos`
--
ALTER TABLE `Carritos`
  ADD PRIMARY KEY (`Id`);

--
-- Indices de la tabla `Compras`
--
ALTER TABLE `Compras`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `IX_Compras_CarritoAsociadoId` (`CarritoAsociadoId`),
  ADD KEY `IX_Compras_UsuarioAsociadoId` (`UsuarioAsociadoId`);

--
-- Indices de la tabla `LineasDeCarrito`
--
ALTER TABLE `LineasDeCarrito`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `IX_LineasDeCarrito_CarritoId` (`CarritoId`),
  ADD KEY `IX_LineasDeCarrito_ProductoId` (`ProductoId`);

--
-- Indices de la tabla `LineasDeCompra`
--
ALTER TABLE `LineasDeCompra`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `IX_LineasDeCompra_CompraAsociadaId` (`CompraAsociadaId`),
  ADD KEY `IX_LineasDeCompra_ProductoAsociadoId` (`ProductoAsociadoId`);

--
-- Indices de la tabla `Productos`
--
ALTER TABLE `Productos`
  ADD PRIMARY KEY (`Id`);

--
-- Indices de la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  ADD PRIMARY KEY (`Id`),
  ADD UNIQUE KEY `IX_Usuarios_Correo` (`Correo`),
  ADD UNIQUE KEY `IX_Usuarios_CarritoAsociadoId` (`CarritoAsociadoId`);

--
-- Indices de la tabla `__EFMigrationsHistory`
--
ALTER TABLE `__EFMigrationsHistory`
  ADD PRIMARY KEY (`MigrationId`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `Carritos`
--
ALTER TABLE `Carritos`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `Compras`
--
ALTER TABLE `Compras`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `LineasDeCarrito`
--
ALTER TABLE `LineasDeCarrito`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `LineasDeCompra`
--
ALTER TABLE `LineasDeCompra`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `Productos`
--
ALTER TABLE `Productos`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `Compras`
--
ALTER TABLE `Compras`
  ADD CONSTRAINT `FK_Compras_Carritos_CarritoAsociadoId` FOREIGN KEY (`CarritoAsociadoId`) REFERENCES `Carritos` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_Compras_Usuarios_UsuarioAsociadoId` FOREIGN KEY (`UsuarioAsociadoId`) REFERENCES `Usuarios` (`Id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `LineasDeCarrito`
--
ALTER TABLE `LineasDeCarrito`
  ADD CONSTRAINT `FK_LineasDeCarrito_Carritos_CarritoId` FOREIGN KEY (`CarritoId`) REFERENCES `Carritos` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_LineasDeCarrito_Productos_ProductoId` FOREIGN KEY (`ProductoId`) REFERENCES `Productos` (`Id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `LineasDeCompra`
--
ALTER TABLE `LineasDeCompra`
  ADD CONSTRAINT `FK_LineasDeCompra_Compras_CompraAsociadaId` FOREIGN KEY (`CompraAsociadaId`) REFERENCES `Compras` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_LineasDeCompra_Productos_ProductoAsociadoId` FOREIGN KEY (`ProductoAsociadoId`) REFERENCES `Productos` (`Id`);

--
-- Filtros para la tabla `Usuarios`
--
ALTER TABLE `Usuarios`
  ADD CONSTRAINT `FK_Usuarios_Carritos_CarritoAsociadoId` FOREIGN KEY (`CarritoAsociadoId`) REFERENCES `Carritos` (`Id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
