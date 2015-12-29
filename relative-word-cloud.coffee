$ = document.querySelector.bind(document)
loadto = (el, url) ->
  fetch url
  .then (resp) -> resp.text()
  .then (body) -> el.value = body

targetSelect = $('#target-select')
targetSelect.addEventListener 'change', ->
  val = targetSelect.options[targetSelect.selectedIndex].value
  return if val is 'custom'
  path = val.split('/')[0]
  if baseOpt = $("#base-select option[value=\"base/#{path}.json\"]")
    baseOpt.selected = true
    updateBase()
  loadto $('#target'), val
    .then doRelative

base = null
baseCache = {}
getBase = (url) ->
  return baseCache[url] if baseCache[url]
  baseCache[url] = fetch(url).then (resp) -> resp.json()


customBase = false
baseSelect = $('#base-select')
updateBase = ->
  baseName = baseSelect.options[baseSelect.selectedIndex].value
  if baseName is 'custom'
    $('#base').disabled = false
    customBase = true
  else
    $('#base').disabled = true
    customBase = false
    base = getBase baseName

baseSelect.addEventListener 'change', updateBase

stopwords = fetch 'stopwords.txt'
  .then (resp) -> resp.text()
  .then (body) ->
    o = {}
    o[line] = true for line in body.split '\n'
    o

process = (el) ->
  words = el.value
    .replace(/[^\w'’]/g, ' ')
    .replace(/  +/g, ' ')
    .toLowerCase()
  return {} if words.length is 0
  words = words.split(' ')
  counts = {}
  counts[word] = counts[word]+1 or 1 for word in words
  counts


$('#traditional').addEventListener 'click', ->
  stopwords.then (stopwords) ->
    counts = process $('#target')
    countsArray = ({word: word, weight: count} for word, count of counts when !stopwords[word])
    countsArray.sort (a, b) -> b.weight - a.weight
    # console.log countsArray
    cloud countsArray.slice(0, 20)

calc = (targetCount, target, baseCount, base) ->
 targetProb = targetCount / target.total
 baseProb = baseCount / base.total
 return targetProb if !baseProb

 usefulness = targetCount / target.max
 (usefulness * targetProb + (1 - usefulness) * baseProb) / (baseProb * 2)

getStats = (words) ->
  total = 0
  num = 0
  max = 0
  for word, count of words
    max = count if count > max
    total += count
    num++
  avg = total / num
  {total, num, avg, max}


doRelative = ->
  if customBase then base = Promise.resolve process $('#base')
  base.then (base) ->
    baseStat = getStats base
    target = process $('#target')
    targetStat = getStats target
    list = ({word: word, weight: calc count, targetStat, (base[word] or 0), baseStat} for word, count of target)
    list.sort (a, b) -> b.weight - a.weight
    # console.log list
    cloud list.slice(0, 20)
$('#relative').addEventListener 'click', doRelative

MINSIZE = 10
MAXSIZE = 72
cloud = (words) ->
  # console.log "words", words
  max = words[0]?.weight or NaN
  min = words[words.length-1]?.weight or 0
  $('#cloud').innerHTML = ''
  for word in words
    span = document.createElement 'span'
    scale = (word.weight - min) / ((max - min) or 1)
    size = Math.round(scale * (MAXSIZE - MINSIZE) + MINSIZE)
    # console.log "word", word.word, word.weight, scale, size
    span.style.fontSize = "#{size}px"
    span.textContent = word.word + ' '
    $('#cloud').appendChild span

base = getBase 'base/pg.json'
loadto $('#target'), 'pg/75 - Microsoft is Dead.txt'
  .then doRelative
