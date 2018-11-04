# Práctica de iOS Avanzado
Partiremos de la App Everpobre que hemos desarrollado en clase. La idea es modificarla y añadirle algunos temas que se vieron en clase.
## Obligatorio
### Mejoras en nuestro modelo
- Añadir al modelo de CoreData la ubicación de cada `Note`. Tomar en cuenta que la ubicación puede estar vacía. Coordenadas (0,0) es un punto real (Isla Null). Tendremos que migrar la versión del modelo `Core Data`.
- Dejamos para después la implementación del campo Tags en la definición de Note. Añadamos un string por ahora.
### Mejoras en NewNotesListViewController
- Modificar NewNotesListViewController de manera las celdas de las collectionView muestren también la imagen de la nota si es que existe o sino un placeholder.
- Ya que tenemos coordenadas en cada Note , ¿no sería interesante mostrar las notas en un mapa?. Hagamos que el NewNotesListViewController tenga un selector donde el usuario pueda cambiar entre la lista y el mapa. ( UISelectedControl tal vez?)
### Mejoras en NotebookListViewController
- En clase vimos la exportación de los Notebooks pero lo grabamos dentro del device. Eso no es muy amigable que digamos. Usemos un UIActivityViewController para poder compartirlo o enviarlo a nosotros mismos. Adicional cambiemos la exportación para la lista de Notebooks asi exportamos toda la info de la App.
## Desafios
### Hacer más robusta nuestra implementación de Tags
Nuestra implementación de Tags no es la mejor que podríamos hacer. Mejoremola un poco. Añadamos un enum:
``` Swift
    enum Tag {
      case Personal
      case Todo
      case Info
      case Otros
    }
```
TIP: CoreData no puede guardar valores de un enum. Para salvar eso podemos definir el Enum con un raw value de algun tipo, por ejemplo Int y guardar ese valor.
No olviden que eso hace que modifiquemos el textfield para que soporte la selección de los valores. Una solución podría ser usar un UIPickerView que solo deje seleccionar un tag de una lista. Por ahora un sólo valor.
Si quisieramos multiselección podriamos implementar otro UIViewController que maneje la selección de opciones y mostremos el string separado con , en la vista de detalle.
### Buscador en NewNotesListViewController
Podemos ver la lista de Notas en la app pero no podemos buscar por Title o por Tag . Añadamos
un campo de busqueda.
### Usemos un NSFetchedResultsController en nuestro collectionView 
Ahora que ya estamos confiados en nuestras habilidades iOS, mejoremos un poco la CollectionView
usando un `NSFetchedResultsController`
Por defecto el `NSFetchedResultsController` esta hecho para usarse en `UITableViews` pero con un poco de adaptación podriamos usarlo en un `UICollectionView`. La mayor diferencia a tomar en cuenta es la modificación de los métodos del delegado ya que a diferencia de un `UITableView` las actualizaciones (updates) no tienen un begin y end , por lo que es necesario guardar todos los cambios y aplicarlos en batch al final.
``` Swift
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequest
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChang
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChang
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestR
```
                     
