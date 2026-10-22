import hashlib
from mysql.connector.errors import Error
import conexion

# El Word pide la tabla en la base de datos db_academica
db = conexion.Conexion("db_academica")

TABLA = "usuarios_usss016325"


def encriptar(clave):
    # MD5 en hexadecimal = 32 caracteres, cabe en clave char(35)
    return hashlib.md5(clave.encode("utf-8")).hexdigest()


class crud_usuarios_usss016325:
    def consultar(self, buscar):
        # No se envia la clave al navegador
        return db.consultar(
            f"""SELECT idUsuario, usuario, nombre, direccion, telefono
                FROM {TABLA}
                WHERE usuario LIKE %s OR nombre LIKE %s""",
            (f"%{buscar}%", f"%{buscar}%")
        )

    def login(self, datos):
        filas = db.consultar(
            f"SELECT idUsuario, usuario, nombre FROM {TABLA} WHERE usuario=%s AND clave=%s",
            (datos.get('usuario', ''), encriptar(datos.get('clave', '')))
        )
        if filas:
            return filas[0]
        return None

    # Metodo CRUD del parcial (lleva el codigo de estudiante en el nombre)
    def crud_usuarios_usss016325(self, datos):
        try:
            if datos['accion'] == 'nuevo':
                sql = f"""
                    INSERT INTO {TABLA}(usuario,clave,nombre,direccion,telefono)
                    VALUES(%s,%s,%s,%s,%s)
                """
                valores = (datos['usuario'], encriptar(datos['clave']), datos['nombre'],
                           datos['direccion'], datos['telefono'])
            elif datos['accion'] == 'modificar':
                if datos['clave'] != '':
                    sql = f"""
                        UPDATE {TABLA} SET usuario=%s,clave=%s,nombre=%s,direccion=%s,telefono=%s
                        WHERE idUsuario=%s
                    """
                    valores = (datos['usuario'], encriptar(datos['clave']), datos['nombre'],
                               datos['direccion'], datos['telefono'], datos['idUsuario'])
                else:
                    # clave vacia = conservar la clave actual
                    sql = f"""
                        UPDATE {TABLA} SET usuario=%s,nombre=%s,direccion=%s,telefono=%s
                        WHERE idUsuario=%s
                    """
                    valores = (datos['usuario'], datos['nombre'], datos['direccion'],
                               datos['telefono'], datos['idUsuario'])
            else:
                sql = f"DELETE FROM {TABLA} WHERE idUsuario=%s"
                valores = (datos['idUsuario'],)
            return db.ejecutar(sql, valores)
        except Error as e:
            return f"Error al guardar el usuario: {e}"
