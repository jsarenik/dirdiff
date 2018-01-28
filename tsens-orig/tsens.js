module.exports = function startup(options, imports, register) {
    var config = require(options.config);
    var later = require('later');
    var async = require('async');
    var Queue = require('bull');
    var queue = new Queue("tsens", 6379, '127.0.0.1', {}, true);

    queue.clean(0, 'active');
    queue.clean(0, 'waiting');
    queue.clean(0, 'delayed');
    queue.clean(0, 'failed');
    queue.clean(0, 'completed');

    function scheduleJobs() {
        var enabled = [];
        async.eachSeries(config, function iteratee(item, callback) {
        var job = item;
        if (job.enabled) {
            setupJob(job, function(err, job) {
                if (err) { 
                    callback(err);
                    console.log("setup for job failed " + job.plugin);
                } else {
                    console.log("setup for job " + job.plugin);
                    enabled.push(job);
                    callback(null, job);
                }
            });
        } else
            callback(null, job);
        }, function done() {
            console.log("resuming priority queue");
            queue.resume().then(function(job) {
                while (enabled.length) {
                    var job = enabled.shift();
                    if (!job.schedule)
                        continue;

                    addJob(job, function(err) {
                        if (err)
                            console.log("adding job failed " + job.plugin);
                        else
                            console.log("adding job for " + job.plugin);
                    });
                }
            });
        });
    }

    function dispatchJob(job, options) {                                    
        console.log("dispatching: " + job.plugin);
        queue.add(job, options);
    }

    function setupJob(job, callback) {
        var plugin = imports.getPlugin(job.plugin);                                      
        try {
            plugin.setup(job, callback);
        } catch (error) {
            return callback(error);
        };
    }

    function endJob(job) {
        if (job.type != "queue")
            return;
        var scheduleSplit;

        var splitCron = job.schedule.split(' ');

        var minuteSplit = splitCron[0].split('-');
        if (minuteSplit[1]) {
            splitCron[0] = minuteSplit[1]
            scheduleSplit = 1;
        } else
            splitCron[0] = 0;

        var hourSplit = splitCron[1].split('-');
        if (hourSplit[1]) {
            splitCron[1] = parseInt(hourSplit[1]) + 1;
            if (splitCron[1] == 24)
                splitCron[1] = 0;
            scheduleSplit = 1;
        }

        if (!scheduleSplit)
            return;

        var endCron = splitCron.join(' ');

        console.log("Scheduling job end of " + endCron);

        var endCronSched = later.parse.cron(endCron);

        later.setInterval(function() {
                dispatchJob({
                    plugin: job.plugin,
                }, {
                    halt: '1'
                })
            },
            endCronSched);
    }

    function addJob(job) {
        dispatchJob({
                plugin: job.plugin,
           },
           job.options)

        if (!job.schedule)
           return;        
       
        var cronSched = later.parse.cron(job.schedule);

        var timer = later.setInterval(function() {
                dispatchJob({
                        plugin: job.plugin,
                    },
                    job.options)
            },
            cronSched
        );

        endJob(job);
    }

    queue.on('ready', function() {                
        console.log("priority queue ready now pause");            
        queue.pause().then(function() {
            register(null, {
                tsens: {
                    scheduleJobs: function() {
                       scheduleJobs();
                    },
                    onDestruct: function(callback) {},
               }
            });

            queue.process(function(job, done) {                                                    
                var plugin = imports.getPlugin(job.data.plugin);                                      
                                                                                              
                console.log("Plugin Submit " + job.data.plugin);                                      
                plugin.run(job.opts, function() {
                    console.log("FINISHED");
                    done();
                });                                                     
            });
        });                                               
    });
};