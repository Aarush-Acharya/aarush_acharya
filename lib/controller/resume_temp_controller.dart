import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ResumeTempController extends GetxController {
  // Is presseds
  var Vercel_isPressed = true.obs;
  var profile_isPressed = true.obs;
  var github_issues_isPressed = true.obs;
  var github_chart_isPressed = true.obs;
  // .........................................

//Data fetch variables
  var profileisthere = false.obs;
  var activity_fetched = false.obs;
  var map_fetched = false.obs;
  var vercel_fetched = false.obs;
// .............................................

  var sending = false.obs;
  var commits = 0;
  var totalCount;

  var contridata;
  var status_deploy;
  var pr_issue_num;
  List PushEvents = [];
  final Map record_push = {};
  List CreateEvents = [];
  List PushRepos = [];
  List CreateRepos = [];
  Map<DateTime, int> impressions = {};

  // Tokens
  var auth_token = "oA2kyJ8EktEKl995UQZUpm4N";
  var git_access_token = "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";
  // ------------------------------------------------------

  var push_repo_names = [];
  var UserInfo;
  var activity;
  var res_get;
  var profile_url;
  var EmailInfo;
  var settings;
  var dep_resp;
  var pr_issue;
  var projects;
  var headers;
  var headers_projects;
  var headers_proxy = {'Content-Type': 'application/json'};
  TextEditingController name_feild = TextEditingController();
  TextEditingController description_feild = TextEditingController();
  TextEditingController email_feild = TextEditingController();
  TextEditingController github_unme_feild = TextEditingController();
  TextEditingController twitter_unme = TextEditingController();
  TextEditingController linkedIn_unme = TextEditingController();

  // onInit()
  @override
  void onInit() async {
    super.onInit();
    await load();
  }
  // ----------------------------------

  Future<void> load() async {
// Get Vercel Projects

    headers_projects = {'Authorization': 'Bearer ${auth_token}'};

    var request_projects =
        http.Request('GET', Uri.parse('https://api.vercel.com/v9/projects'));

    request_projects.headers.addAll(headers_projects);

    http.StreamedResponse response_projects = await request_projects.send();

    print("Getting vercel deploys");

    if (response_projects.statusCode == 200) {
      print("Got projects");
      projects = await response_projects.stream.bytesToString();
      projects = jsonDecode(projects);
      projects = projects["projects"];
      vercel_fetched.value = true;
    } else {
      print("Could not get projects");
      print(response_projects.reasonPhrase);
    }

    headers = {
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer ${git_access_token}',
      'X-GitHub-Api-Version': '2022-11-28'
    };

// Get Git User

    var request = http.Request('GET', Uri.parse('https://api.github.com/user'));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print("Got User");
      UserInfo = await response.stream.bytesToString();
      UserInfo = jsonDecode(UserInfo);

      profile_url = UserInfo['avatar_url'].toString();
      name_feild.text = UserInfo['name'];
      github_unme_feild.text = UserInfo['login'];
      description_feild.text = UserInfo['bio'];
      profileisthere.value = true;
    } else {
      print("Did not get user");
      print(response.reasonPhrase);
    }

// Get Git User Emails

    var request_email =
        http.Request('GET', Uri.parse('https://api.github.com/user/emails'));
    request_email.headers.addAll(headers);

    http.StreamedResponse response_emails = await request_email.send();

    if (response_emails.statusCode == 200) {
      print("Got email");
      EmailInfo = await response_emails.stream.bytesToString();
      EmailInfo = jsonDecode(EmailInfo);
      email_feild.text = EmailInfo[0]["email"];
    } else {
      print("Could not get email");
      print(response_emails.reasonPhrase);
    }
    await getGithubActivity();
    print("Got Activity");
    await getGithubMap();
    print("Got Maps");
  }

  Future<void> getGithubActivity() async {
    // Get Git Activity
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://api.github.com/users/${UserInfo['login']}/events?q=per_page:100'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      activity = await response.stream.bytesToString();
      activity = jsonDecode(activity);

      for (var i = 0; i < activity.length; i++) {
        if (activity[i]['type'] == "PushEvent") {
          PushRepos.add({
            activity[i]['repo']['name']:
                activity[i]['payload']['commits'].length
          });
          PushEvents.add(activity[i]);
          push_repo_names.add(activity[i]['repo']['name']);
        } else if (activity[i]['type'] == "CreateEvent") {
          CreateEvents.add(activity[i]);
          CreateRepos.add(activity[i]['repo']['name']);
        }
      }
      push_repo_names = push_repo_names.toSet().toList();
      for (int l = 0; l < PushRepos.length; l++) {
        var key = PushRepos[l].keys.toList();
        key = key[0];
        record_push.containsKey(key)
            ? record_push[key] += PushRepos[l][key]
            : record_push[key] = PushRepos[l][key];
      }
      record_push.keys.forEach((k) {
        commits += record_push[k] as int;
      });
      CreateRepos = CreateRepos.toSet().toList();
      var request_pr_issue = http.Request(
          'GET',
          Uri.parse('https://api.github.com/search/issues?q=author:Aarush-Acharya&type:issue&state:open&is:open'));

      request_pr_issue.headers.addAll(headers);

      http.StreamedResponse response_pr_issue = await request_pr_issue.send();

      if (response_pr_issue.statusCode == 200) {
        pr_issue = await response_pr_issue.stream.bytesToString();
        pr_issue = jsonDecode(pr_issue);
        pr_issue_num = pr_issue["total_count"];
      } else {
        print(response_pr_issue.reasonPhrase);
      }
      activity_fetched.value = true;
    } else {
      print(response.reasonPhrase);
    }
  }

  Future<void> getGithubMap() async {
    //Get Map Data
    var headers = {
      'Authorization': 'bearer ${git_access_token}',
      'Content-Type': 'text/plain'
    };
    var request =
        http.Request('POST', Uri.parse('https://api.github.com/graphql'));
    request.body =
        '''{"query":"query {\\n  user(login: \\"${UserInfo['login']}\\") {\\n    name\\n    contributionsCollection {\\n      contributionCalendar {\\n        colors\\n        totalContributions\\n        weeks {\\n          contributionDays {\\n            color\\n            contributionCount\\n            date\\n            weekday\\n          }\\n          firstDay\\n        }\\n      }\\n    }\\n  }\\n}"}''';
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      contridata = await response.stream.bytesToString();
      contridata = jsonDecode(contridata);
      contridata = contridata["data"]["user"]["contributionsCollection"]
          ["contributionCalendar"];
      totalCount = contridata["totalContributions"];
      contridata = contridata["weeks"];
      for (int i = 0; i < contridata.length; i++) {
        for (int j = 0; j < contridata[i]["contributionDays"].length; j++) {
          if (contridata[i]["contributionDays"][j]["contributionCount"] != 0) {
            impressions[DateTime.parse(
                    contridata[i]["contributionDays"][j]["date"])] =
                contridata[i]["contributionDays"][j]["contributionCount"];
          }
        }
      }
      print("flag check");
      map_fetched.value = true;
    } else {
      print(response.reasonPhrase);
    }
  }
}
