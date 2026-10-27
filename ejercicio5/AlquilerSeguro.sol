// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AlquilerSeguro
 * @dev Contrato inteligente para la gestion de alquileres temporales y fianzas con optimizacion de gas.
 */
contract AlquilerSeguro {
    address payable public immutable propietario;
    uint256 public immutable precioAlquiler;
    uint256 public immutable fianza;

    address payable public inquilino;

    // Tipo enumerado para controlar el ciclo de vida del contrato
    enum Estado { Disponible, Alquilado, Finalizado }
    Estado public estado;

    // Registro desacoplado de fondos listos para retirar (patron Pull-Payment)
    mapping(address => uint256) public saldoPendiente;

    // Eventos informativos para seguimiento de transacciones
    event PropiedadAlquilada(address indexed inquilino, uint256 totalDepositado);
    event AlquilerFinalizado(bool retencionPorDanos, uint256 fianzaDevuelta);
    event FondosRetirados(address indexed usuario, uint256 cantidad);

    // Modificadores de control de acceso y estado
    modifier soloPropietario() {
        require(msg.sender == propietario, "Solo el propietario puede ejecutar esto");
        _;
    }

    modifier soloInquilino() {
        require(msg.sender == inquilino, "Solo el inquilino puede ejecutar esto");
        _;
    }

    modifier enEstado(Estado _estadoEsperado) {
        require(estado == _estadoEsperado, "Estado del contrato incompatible");
        _;
    }

    /**
     * @notice Constructor que fija las condiciones iniciales del alquiler
     * @param _precioEnEther Coste del alquiler en ETH
     * @param _fianzaEnEther Coste de la fianza en ETH
     */
    constructor(uint256 _precioEnEther, uint256 _fianzaEnEther) {
        require(_precioEnEther > 0, "El precio de alquiler debe ser mayor a 0");
        propietario = payable(msg.sender);
        precioAlquiler = _precioEnEther * 1 ether;
        fianza = _fianzaEnEther * 1 ether;
        estado = Estado.Disponible;
    }

    /**
     * @notice Permite al inquilino reservar enviando el alquiler mas la fianza exacta
     * @dev Funcion external para abaratar coste de gas frente a public
     */
    function alquilar() external payable enEstado(Estado.Disponible) {
        require(msg.value == (precioAlquiler + fianza), "Debe enviar exactamente el alquiler mas la fianza");

        inquilino = payable(msg.sender);
        estado = Estado.Alquilado;

        emit PropiedadAlquilada(msg.sender, msg.value);
    }

    /**
     * @notice Cierra el contrato sin desperfectos: el casero cobra la renta y el inquilino recupera su fianza
     */
    function finalizarSinIncidencias() external soloPropietario enEstado(Estado.Alquilado) {
        estado = Estado.Finalizado;

        // Desacople de saldos
        saldoPendiente[propietario] += precioAlquiler;
        saldoPendiente[inquilino] += fianza;

        emit AlquilerFinalizado(false, fianza);
    }

    /**
     * @notice Cierra el contrato reteniendo la fianza por daños: el propietario cobra renta + fianza
     */
    function reclamarPorDanos() external soloPropietario enEstado(Estado.Alquilado) {
        estado = Estado.Finalizado;

        saldoPendiente[propietario] += (precioAlquiler + fianza);

        emit AlquilerFinalizado(true, 0);
    }

    /**
     * @notice Permite a cada usuario retirar el saldo asignado de forma segura contra ataques reentrancy
     */
    function retirarFondos() external {
        uint256 cantidad = saldoPendiente[msg.sender];
        require(cantidad > 0, "No dispone de fondos pendientes para retirar");

        // Actualizacion del estado antes de la llamada de transferencia
        saldoPendiente[msg.sender] = 0;

        (bool exito, ) = payable(msg.sender).call{value: cantidad}("");
        require(exito, "Fallo al transferir los fondos");

        emit FondosRetirados(msg.sender, cantidad);
    }

    /**
     * @notice Consulta el saldo de Ether almacenado actualmente en el contrato
     */
    function obtenerBalanceContrato() external view returns (uint256) {
        return address(this).balance;
    }
}