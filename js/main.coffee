##############
# Navigation #
##############
get_hash = ->
  hash = location.hash.slice(1)
  hash or 'home'

navigate = ->
  hash = get_hash()
  all = ['_home', '_graph', '_algorithm']
  target = "_#{hash}"

  hide = (c) ->
    $(".#{c}").hide()
    $(".#{c}_nav").removeClass 'active'

  show = (c) ->
    $(".#{c}").show()
    $(".#{c}_nav").addClass 'active'

  (hide c if c != target) for c in all
  show target

  # Notify for `pageshow-PAGE` event via $.trigger
  $(window).trigger "pageshow-#{hash}"

# Bind to event and navigate initially when page is ready
$(window).on 'hashchange', navigate
$ navigate


#########
# Graph #
#########
$('._edgeDeleteButton').click ->
  $(this).parents('._edgeRow').remove()

$('#addEdgeButton').click ->
  model = $ '#edgeRowModel'
  clone = model.clone true, true
  clone.removeClass('hide')
  clone.attr('id', '')
  $('#edgeTableBody').append clone

get_edges = ->
  "Return a list of all edges as defined in this page."
  arr = $.map $('._edgeRow'), (element, index) ->
    start = $(element).find('._startVertex').val()
    end = $(element).find('._endVertex').val()
    weight = parseInt($(element).find('._edgeWeight').val(), 10)

    # Return an object with these keys if all values are present,
    # otherwise return null
    if start and end and weight
      start: start
      end: end
      weight: weight
    else
      null

  # Skip null elements and return
  arr.filter (e) -> e

get_vertexes = ->
  set = {}
  arr = $.map $('._edgeRow'), (element, index) ->
    start = $(element).find('._startVertex').val()
    end = $(element).find('._endVertex').val()
    if start and not set.hasOwnProperty start
      set[start] = true
    if end and not set.hasOwnProperty end
      set[end] = true
  (x for x of set when set.hasOwnProperty(x))


######################
# Dijkstra algorithm #
######################
smallest_dist = (vertexes, dist) ->
  min = Infinity
  minVertex = null
  for vertex in vertexes
    if dist.hasOwnProperty(vertex) and dist[vertex] < min
      min = dist[vertex]
      minVertex = vertex
  return minVertex

get_neighbours = (vertex, edges) ->
  ret = []
  for edge in edges
    if edge.start == vertex
      ret.push edge.end
    else if edge.end == vertex
      ret.push edge.start
  return ret

dist_between = (v, u, edges) ->
  for edge in edges
    if (edge.start == v and edge.end == u) or
       (edge.start == u and edge.end == v)
      return edge.weight
  throw new Error "No edge between #{u} and #{v}"

trace = (start, paths) ->
  S = []
  while paths[start]
    S.push(start)
    start = paths[start]
  S.reverse()

# Pseudocode at http://is.gd/Jc2ZAP
dijkstra = (vertexes, edges, source, target) ->
  dist = {}
  previous = {}
  for vertex in vertexes
    dist[vertex] = Infinity
    previous[vertex] = null
  dist[source] = 0
  Q = (v for v in vertexes)
  while Q.length > 0
    u = smallest_dist Q, dist
    if u is target
      S = trace target, previous
      S.unshift source
      return S
    Q.splice Q.indexOf(u), 1
    if dist[u] is Infinity
      break
    for v in get_neighbours u, edges
      alt = dist[u] + dist_between u, v, edges
      if alt < dist[v]
        dist[v] = alt
        previous[v] = u
  # return dist
  return []

##################
# Algorithm page #
##################
populateSelect = (id, values) ->
  $("##{id}").empty()
  for val in values
    $("##{id}").append(
      $("<option value=\"#{val}\">#{val}</option>")
    )

$(window).bind 'pageshow-algorithm', ->
  vertexes = get_vertexes()
  populateSelect 'startVertexSelect', vertexes
  populateSelect 'endVertexSelect', vertexes

solve = ->
  start = $('#startVertexSelect').val()
  end = $('#endVertexSelect').val()
  edges = get_edges()
  path = dijkstra get_vertexes(), edges, start, end
  $('#solutionTable').empty()
  path.reduce (prev, current, index, array) ->
    dist = dist_between prev, current, edges
    $('#solutionTable').append "
<tr>
  <td>#{index}</td>
  <td>#{prev}</td>
  <td>#{current}</td>
  <td>#{dist}</td>
</tr>"
    current

$ ->
  $('#startVertexSelect').change solve
  $('#endVertexSelect').change solve
  # Solve initially
