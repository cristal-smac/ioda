package fr.cristal.ioda;

import java.util.List;
import java.util.WeakHashMap ;
import java.util.Iterator ;
// added in 2.3
import java.util.regex.* ;

import java.io.IOException ;

import org.nlogo.api.*;
import org.nlogo.core.ExtensionObject;
import org.nlogo.agent.Agent ;
import org.nlogo.agent.Turtle ;
import org.nlogo.agent.Patch ;
import org.nlogo.core.LogoList ;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;
import org.nlogo.core.Nobody ;


/** <p>This class is part of the IODA NetLogo extension.<bR> All
 * contents &copy; 2008-2024 Sébastien PICAULT and Philippe
 * MATHIEU<br> Centre de Recherche en Informatique, Signal et
 * Automatique de Lille (CRIStAL), UMR CNRS 9189<br> Université de
 * Lille (Sciences et Technologies) – Cité Scientifique, F-59655
 * Villeneuve d'Ascq Cedex, FRANCE.<br> Web Site: <a
 * href="https://github.com/cristal-smac/ioda">https://github.com/cristal-smac/ioda</a></p>
 * <p>The IODA NetLogo extension is free software: you can
 * redistribute it and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later
 * version.</p> <p>The IODA NetLogo extension is distributed in the
 * hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE. See the GNU General Public License for more details.</p>
 * <p>You should have received a copy of the GNU General Public
 * License along with the IODA NetLogo extension. If not, see <a
 * href="http://www.gnu.org/licenses">http://www.gnu.org/licenses</a>.</p>
 *
 * @author Sébastien Picault
 * @author Nathan Hallez
 * @author Philippe Mathieu
 *
 * @see <a href="https://www.cristal.univ-lille.fr/SMAC/projects/ioda/index-2.html">The IODA Webpage</a>
 * @version IODA Extension 3.0 - Jul. 2024
 */
public class Interaction implements ExtensionObject {
	public static enum Category { PARALLEL, EXCLUSIVE } ;
	private static Category defaultCategory = Category.PARALLEL ;

	public static void setDefaultCategory(Category c) { defaultCategory = c ; }

	static WeakHashMap<String, Interaction> interactions = new WeakHashMap<String,Interaction>() ;
	private static long next = 0 ;

	public static void readFromString(String fileName, String fileContent) throws IOException, ExtensionException {
		Pattern triggerPattern = null, conditionPattern = null, interactionPattern = null, commentPattern = null ;
		try {
			commentPattern = Pattern.compile("[^a-zA-Z0-9_\\?\\-:\\s].*?$",
					Pattern.MULTILINE) ;
		} catch(PatternSyntaxException e) {
			throw new ExtensionException("ERROR IN COMMENT PATTERN WHEN READING FILE "
					+ fileName + "\n" + e.getMessage()) ;
		}
		try {
			triggerPattern = Pattern.compile("^\\s*trigger\\s+((\\s*([\\w:\\-]+\\??))+?)\\s*?$",
					Pattern.MULTILINE+Pattern.CASE_INSENSITIVE) ;
		} catch (PatternSyntaxException e) {
			throw new ExtensionException("ERROR IN TRIGGER PATTERN WHEN READING FILE "
					+ fileName + "\n" + e.getMessage()) ;
		}
		try {
			conditionPattern = Pattern.compile("^\\s*condition\\s+((\\s*([\\w:\\-]+\\??))+?)\\s*?$",
					Pattern.MULTILINE+Pattern.CASE_INSENSITIVE) ;
		} catch (PatternSyntaxException e) {
			throw new ExtensionException("ERROR IN TRIGGER PATTERN WHEN READING FILE "
					+ fileName + "\n" + e.getMessage()) ;
		}
		try {
			interactionPattern = Pattern.compile("^\\s*((exclusive|parallel)\\s+)?interaction\\s+([\\w\\-]*)\\s*?" +
							"^(" +
							"((^\\s*trigger\\s+((\\s*([\\w:\\-]+\\??))+?)\\s*?\\n)*?)" +
							"((^\\s*condition\\s+((\\s*([\\w:\\-]+\\??))+?)\\s*\\n)*?)" +
							"(^\\s*actions\\s+((\\s*([\\w:\\-]+))+?)\\s*\\n)*?" +
							")\\s*end\\s*?$",
					Pattern.MULTILINE+Pattern.CASE_INSENSITIVE) ;
		} catch (PatternSyntaxException e) {
			throw new ExtensionException("ERROR IN TRIGGER PATTERN WHEN READING FILE "
					+ fileName + "\n" + e.getMessage()) ;
		}

		Matcher commentMatcher = commentPattern.matcher(fileContent) ;
		String newFileContent = commentMatcher.replaceAll("") ;
		System.out.println(fileContent + "\n\n\n" + newFileContent) ;
		Matcher interactionMatcher = interactionPattern.matcher(newFileContent) ;
		while (interactionMatcher.find()) {
			String name = interactionMatcher.group(3) ;
			boolean exclusive = false ;
			if (interactionMatcher.group(2) !=null)
				exclusive = interactionMatcher.group(2).equalsIgnoreCase("exclusive") ;
			String trigline, condline, actline ;
			trigline = interactionMatcher.group(5) ;
			condline = interactionMatcher.group(10) ;
			actline = interactionMatcher.group(16) ;
			LogoListBuilder trigger = new LogoListBuilder() ;
			LogoListBuilder condition = new LogoListBuilder() ;
			LogoListBuilder actions = new LogoListBuilder() ;
			Matcher triggerMatcher = triggerPattern.matcher(trigline) ;
			Matcher conditionMatcher = conditionPattern.matcher(condline) ;
			while (triggerMatcher.find()) {
				LogoListBuilder tmp = new LogoListBuilder() ;
				for (String s: triggerMatcher.group(1).split("\\s+"))
					tmp.add(s) ;
				trigger.add(tmp.toLogoList()) ;
			}
			while (conditionMatcher.find()) {
				LogoListBuilder tmp = new LogoListBuilder() ;
				for (String s: conditionMatcher.group(1).split("\\s+"))
					tmp.add(s) ;
				condition.add(tmp.toLogoList()) ;
			}
			if (actline !=null)
				for (String s: actline.split("\\s+"))
					actions.add(s) ;
			Interaction i = new Interaction(name, trigger.toLogoList(), condition.toLogoList(), actions.toLogoList()) ;
			i.setExclusive(exclusive) ;
		}
	}


	private final long id ;
	private LogoList trigger, condition, actions ;
	private final String name ;
	private Category status = defaultCategory ;

	public String toString() {
		StringBuffer b = new StringBuffer() ;
		b.append(((this.isExclusive())?"EXCLUSIVE":"PARALLEL") + " INTERACTION " + this.getName()+"\n") ;
		for (Object o: this.getTrigger().javaIterable()) {
			LogoList l = (LogoList) o ;
			String s = "  TRIGGER\t" ;
			for (Object o2: l.javaIterable())
				s += o2 + " " ;
			b.append(s+"\n") ;
		}
		for (Object o: this.getCondition().javaIterable()) {
			LogoList l = (LogoList) o ;
			String s = "  CONDITION\t" ;
			for (Object o2: l.javaIterable())
				s += o2 + " " ;
			b.append(s+"\n") ;
		}
		if (!this.getActions().isEmpty()) {
			String s = "  ACTIONS\t" ;
			for (Object o: this.getActions().javaIterable())
				s += o + " " ;
			b.append(s+"\n") ;
		}
		b.append("END\n") ;
		return b.toString() ;
	}

	public static void clearAll() {
		interactions.clear() ;
		next = 0 ;
	}

	public static Interaction get(String name) {
		if (interactions.containsKey(name.toLowerCase()))
			return interactions.get(name.toLowerCase()) ;
		return null ;
	}

	public Interaction(String name) {
		this.name = name.toLowerCase() ;
		interactions.put(this.name, this) ;
		id = next ;
		next++ ;
	}

	public Interaction(String name, LogoList trigger, LogoList condition, LogoList actions) {
		this(name) ;
		setTrigger(trigger) ;
		setCondition(condition) ;
		setActions(actions) ;
	}

	public Interaction(LogoList aList) {
		this((String)aList.first()) ;
		if (aList.size() > 1)
			setTrigger((LogoList)aList.get(1)) ;
		if (aList.size() > 2)
			setCondition((LogoList)aList.get(2)) ;
		if (aList.size() > 3)
			setActions((LogoList)aList.get(3)) ;
	}

	public void setTrigger(LogoList trigger) { this.trigger = trigger ; }
	public void setCondition(LogoList condition) { this.condition = condition ; }
	public void setActions(LogoList actions) { this.actions = actions ; }
	private void setCategory(Category c) { status = c ; }
	public void setExclusive(boolean t) {
		if (t) setCategory(Category.EXCLUSIVE) ;
		else  setCategory(Category.PARALLEL) ;
	}

	public boolean isExclusive() { return status.equals(Category.EXCLUSIVE) ; }
	public String getName() { return name ; }
	public long getId() { return id ; }
	public LogoList getTrigger() { return (trigger == null?(new LogoListBuilder()).toLogoList():this.trigger) ; }
	public LogoList getCondition() { return (condition == null?(new LogoListBuilder()).toLogoList():this.condition) ; }
	public LogoList getActions() { return (actions == null?(new LogoListBuilder()).toLogoList():this.actions) ; }

	public boolean equals(Object obj) { return this == obj ; }

	public LogoList toList() {
		LogoListBuilder aList = new LogoListBuilder() ;
		aList.add(this.getName()) ;
		aList.add(this.getTrigger()) ;
		aList.add(this.getCondition()) ;
		aList.add(this.getActions()) ;
		return aList.toLogoList() ;
	}

	public String dump(boolean readable, boolean exportable, boolean reference) {
		if (exportable && reference)
			return ("" + id) ;
		else
			return (exportable?(id+": "):"") + org.nlogo.api.Dump.logoObject(this.toList(), true, exportable) ;
	}

	public String getExtensionName() { return "ioda" ; }
	public String getNLTypeName() { return "interaction" ; }

	public boolean recursivelyEqual(Object o) {
		if (!(o instanceof Interaction))
			return false ;
		Interaction i = (Interaction) o ;
		if ((i.getTrigger().size() != this.getTrigger().size()) ||
				(!(i.getTrigger().toJava().containsAll(this.getTrigger().toJava()) && (this.getTrigger().toJava().containsAll(i.getTrigger().toJava())))) ||
				(i.getCondition().size() != this.getCondition().size()) ||
				(!(i.getCondition().toJava().containsAll(this.getCondition().toJava()) && (this.getCondition().toJava().containsAll(i.getCondition().toJava())))))
			return false ;
		return this.getActions().equals(i.getActions()) ;
	}

	public LogoList evalReporters(LogoList reporters, Agent source, Agent target) {
		LogoListBuilder result = new LogoListBuilder() ;
		if (reporters.isEmpty())
			return result.toLogoList() ;

		String sourceBreed, targetBreed ;
		if (source instanceof Patch)
			sourceBreed = "patches" ;
		else sourceBreed = ((Turtle)source).getBreed().printName() ;
		if (target == null)
			targetBreed = "nobody" ;
		else if (target instanceof Patch)
			targetBreed = "patches" ;
		else targetBreed = ((Turtle)target).getBreed().printName() ;
		LogoListBuilder sourceIdentifier = new LogoListBuilder() ;
		LogoListBuilder targetIdentifier = new LogoListBuilder() ;
		if (sourceBreed.equals("patches")) {
			sourceIdentifier.add((double) ((Patch)source).pxcor()) ;
			sourceIdentifier.add((double) ((Patch)source).pycor()) ;
		} else sourceIdentifier.add(Long.valueOf(source.id()).doubleValue()) ;
		if (!targetBreed.equals("nobody")) {
			if (targetBreed.equals("patches")) {
				targetIdentifier.add((double) ((Patch)target).pxcor()) ;
				targetIdentifier.add((double) ((Patch)target).pycor()) ;
			} else targetIdentifier.add(Long.valueOf(target.id()).doubleValue()) ;
		}

		Iterator<Object> it2 = reporters.javaIterator();
		while (it2.hasNext()) {
			LogoListBuilder srcList, tgtList ;
			LogoListBuilder tmp ;
			srcList = new LogoListBuilder() ;
			tgtList = new LogoListBuilder() ;
			boolean emptySrcList = true ;
			boolean emptyTgtList = true ;
			LogoList tmp2 = (LogoList) it2.next() ;
			Iterator<Object> it = tmp2.javaIterator();
			while (it.hasNext()) {
				tmp = new LogoListBuilder() ;
				String reporter = (String) it.next() ;
				boolean not = false ; // 2.3 addition
				if (reporter.startsWith("not:")) { // 2.3 addition
					not = !not ;		  // 2.3 addition
					reporter = reporter.substring(4) ; // 2.3 addition
				}					   // 2.3 addition
				if (reporter.startsWith("target:")) {
					if (!targetBreed.equals("nobody")) {
						reporter = reporter.substring(7) ;
						if (reporter.startsWith("not:")) { // 2.3 addition
							not = !not ;		  // 2.3 addition
							reporter = reporter.substring(4) ; // 2.3 addition
						}					   // 2.3 addition
						if (not) {				   // 2.3 addition
							tmp.add("not") ;			   // 2.3 addition
							not = false ;			   // 2.3 addition
						}					   // 2.3 addition
						tmp.add(targetBreed+"::"+reporter) ;
						tmp.add(sourceIdentifier.toLogoList()) ;
						tgtList.add(tmp.toLogoList()) ;
						emptyTgtList = false ;
					}
				} else {
					if (not) {		 // 2.3 addition
						tmp.add("not") ; // 2.3 addition
						not = false ;	 // 2.3 addition
					}			 // 2.3 addition
					tmp.add(sourceBreed+"::"+reporter) ;
					tmp.add(targetIdentifier.toLogoList()) ;
					srcList.add(tmp.toLogoList()) ;
					emptySrcList = false ;
				}
			}
			LogoListBuilder result2 = new LogoListBuilder() ;
			if (!emptySrcList)
				result2.add(fput(sourceIdentifier.toLogoList(), srcList.toLogoList())) ;
			if (!emptyTgtList)
				result2.add(fput(targetIdentifier.toLogoList(), tgtList.toLogoList())) ;
			result.add(result2.toLogoList()) ;
		}
		return result.toLogoList() ;
	}


	public LogoList performActions(LogoList commands, Agent source, Object target) {
		LogoListBuilder result = new LogoListBuilder() ;
		if (commands.size() == 0)
			return result.toLogoList() ;
		boolean listTarget = false ;
		String sourceBreed, targetBreed ;
		if (source instanceof Patch)
			sourceBreed = "patches" ;
		else sourceBreed = ((Turtle)source).getBreed().printName() ;
		if (target == null)
			targetBreed = "nobody" ;
		else if (target instanceof Patch)
			targetBreed = "patches" ;
		else if (target instanceof Turtle)
			targetBreed = ((Turtle)target).getBreed().printName() ;
		else if (target instanceof LogoList) {
			listTarget = true ;
			if (((LogoList)target).get(0) instanceof Patch)
				targetBreed = "patches" ;
			else targetBreed = ((Turtle)((LogoList)target).get(0)).getBreed().printName() ;
		}
		else targetBreed = "nobody" ;
		LogoListBuilder sourceIdentifier = new LogoListBuilder() ;
		LogoListBuilder targetIdentifier = new LogoListBuilder() ;
		if (sourceBreed.equals("patches")) {
			sourceIdentifier.add((double) ((Patch)source).pxcor()) ;
			sourceIdentifier.add((double) ((Patch)source).pycor()) ;
		} else sourceIdentifier.add(Long.valueOf(source.id()).doubleValue()) ;
		if (!targetBreed.equals("nobody")) {
			if (listTarget) {
				Iterator<Object> itt = ((LogoList)target).javaIterator();
				while (itt.hasNext()) {
					LogoListBuilder tgtlist = new LogoListBuilder() ;
					Object atgt = itt.next() ;
					if (targetBreed.equals("patches")) {
						tgtlist.add((double) ((Patch)atgt).pxcor()) ;
						tgtlist.add((double) ((Patch)atgt).pycor()) ;
					} else tgtlist.add(Long.valueOf(((Turtle)atgt).id()).doubleValue()) ;
					targetIdentifier.add(tgtlist.toLogoList()) ;
				}
			} else {
				if (targetBreed.equals("patches")) {
					targetIdentifier.add((double) ((Patch)target).pxcor()) ;
					targetIdentifier.add((double) ((Patch)target).pycor()) ;
				} else targetIdentifier.add(Long.valueOf(((Turtle)target).id()).doubleValue()) ;
			}
		}

		LogoListBuilder currentList = new LogoListBuilder() ;
		boolean emptyCurrentList = true ;
		boolean sourceCommands = true ;
		LogoListBuilder tmp ;
		Iterator<Object> it = commands.javaIterator();
		while (it.hasNext()) {
			tmp = new LogoListBuilder() ;
			String command = (String) it.next() ;
			if (command.startsWith("target:")) {
				if (!targetBreed.equals("nobody")) {
					if (sourceCommands && (!emptyCurrentList)) {
						result.add(fput(sourceIdentifier.toLogoList(), currentList.toLogoList()));
						currentList = new LogoListBuilder() ;
						emptyCurrentList = true ;
					}
					sourceCommands = false ;
					command = command.substring(7) ;
					tmp.add(targetBreed+"::"+command) ;
					tmp.add(sourceIdentifier.toLogoList()) ;
					currentList.add(tmp.toLogoList()) ;
					emptyCurrentList = false ;
				}
			} else {
				if (!sourceCommands && (!emptyCurrentList)) {
					result.add(fput(targetIdentifier.toLogoList(), currentList.toLogoList())) ;
					currentList = new LogoListBuilder() ;
					emptyCurrentList = true ;
				}
				sourceCommands = true ;
				tmp.add(sourceBreed+"::"+command) ;
				tmp.add(targetIdentifier.toLogoList()) ;
				currentList.add(tmp.toLogoList()) ;
				emptyCurrentList = false ;
			}
		}
		if (!emptyCurrentList) {
			if (sourceCommands)
				result.add(fput(sourceIdentifier.toLogoList(), currentList.toLogoList())) ;
			else
				result.add(fput(targetIdentifier.toLogoList(), currentList.toLogoList())) ;
		}
		return result.toLogoList() ;
	}

	public static LogoList fput(LogoList l1, LogoList l2) {
		LogoListBuilder tmp = new LogoListBuilder() ;
		tmp.add(l1) ;
		tmp.addAll(l2) ;
		return tmp.toLogoList() ;
	}

	//----------------------------------------------------------------
	public static class LoadInteractions  implements Command {
		public Syntax getSyntax() {
			return SyntaxJ.commandSyntax(new int[] {Syntax.StringType(), Syntax.StringType()}) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public void perform(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			try { //readFromFile(((ExtensionContext)context).attachCurrentDirectory(args[0].getString())) ; }
				readFromString(args[0].getString(), args[1].getString()) ; }
			catch(IOException e) {
				throw new ExtensionException(e.getMessage()) ;
			}
		}
	}

	//----------------------------------------------------------------
	public static class SetExclusiveInteractions implements Command {
		public Syntax getSyntax() {
			return SyntaxJ.commandSyntax(new int[] {Syntax.BooleanType()}) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public void perform(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			if (args[0].getBoolean())
				setDefaultCategory(Category.EXCLUSIVE) ;
			else
				setDefaultCategory(Category.PARALLEL) ;
		}
	}

	//----------------------------------------------------------------
	public static class SetExclusive  implements Command {
		public Syntax getSyntax() {
			return SyntaxJ.commandSyntax(new int[] {Syntax.WildcardType(), Syntax.BooleanType()}) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public void perform(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (! (arg0 instanceof Interaction))
				throw new ExtensionException("not an interaction: " + Dump.logoObject(arg0)) ;
			Interaction i = (Interaction) arg0 ;
			i.setExclusive(args[1].getBoolean()) ;
		}
	}

	//----------------------------------------------------------------
	public static class IsExclusive implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.BooleanType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (! (arg0 instanceof Interaction))
				throw new ExtensionException("not an interaction: " + Dump.logoObject(arg0)) ;
			Interaction i = (Interaction) arg0 ;
			return i.isExclusive() ;
		}
	}

	//----------------------------------------------------------------
	public static class InteractionName implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.StringType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (! (arg0 instanceof Interaction))
				throw new ExtensionException("not an interaction: " + Dump.logoObject(arg0)) ;
			Interaction i = (Interaction) arg0 ;
			return i.getName() ;
		}
	}

	//----------------------------------------------------------------
	public static class InteractionMake implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.StringType(), Syntax.ListType(), Syntax.ListType(), Syntax.ListType()},
					Syntax.WildcardType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			return new Interaction(args[0].getString(), args[1].getList(), args[2].getList(), args[3].getList()) ;
		}
	}

	//----------------------------------------------------------------
	public static class InteractionFromList implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.ListType()}, Syntax.WildcardType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			return new Interaction(args[0].getList()) ;
		}
	}

	//----------------------------------------------------------------
	public static class GetInteractions implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {}, Syntax.ListType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			LogoListBuilder l = new LogoListBuilder() ;
			l.addAll(interactions.values()) ;
			return l.toLogoList() ;
		}
	}

	//----------------------------------------------------------------
	public static class PrintInteractions implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {}, Syntax.StringType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			StringBuffer b = new StringBuffer() ;
			for (Interaction i: interactions.values())
				b.append(i.toString() + "\n");
			return b.toString() ;
		}
	}


	//----------------------------------------------------------------
	public static class GetInteraction implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.StringType()}, Syntax.WildcardType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			String name = args[0].getString().toLowerCase() ;
			if (interactions.containsKey(name))
				return interactions.get(name) ;
			return false ;
		}
	}

	//----------------------------------------------------------------
	public static class EvalTrigger implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType(), (Syntax.AgentType() | Syntax.NobodyType())}, Syntax.ListType()) ;
		}
		public String getAgentClassString() { return "TP" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (! (arg0 instanceof Interaction))
				throw new ExtensionException("not an interaction: " + Dump.logoObject(arg0)) ;
			Interaction i = (Interaction) arg0 ;
			Agent target = null ;
			try {
				target = (Agent)  args[1].get() ;
			} catch (ClassCastException e) {}
			if (! ((target instanceof Turtle) || (target instanceof Patch) || (target == null)))
				throw new ExtensionException("Second argument of eval-trigger should be a turtle or patch or nobody") ;
			return i.evalReporters(i.getTrigger(), (Agent)context.getAgent(), target) ;
		}
	}

	//----------------------------------------------------------------
	public static class EvalCondition implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType(), (Syntax.AgentType() | Syntax.NobodyType())}, Syntax.ListType()) ;
		}
		public String getAgentClassString() { return "TP" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (! (arg0 instanceof Interaction))
				throw new ExtensionException("not an interaction: " + Dump.logoObject(arg0)) ;
			Interaction i = (Interaction) arg0 ;
			Agent target = null ;
			try {
				target = (Agent)  args[1].get() ;
			} catch (ClassCastException e) {}
			if (! ((target instanceof Turtle) || (target instanceof Patch) || (target == null)))
				throw new ExtensionException("Second argument of eval-condition should be a turtle or patch or nobody") ;
			return i.evalReporters(i.getCondition(), (Agent)context.getAgent(), target) ;
		}
	}

	//----------------------------------------------------------------
	public static class PerformActions implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType(), (Syntax.AgentType() | Syntax.ListType() | Syntax.NobodyType())}, Syntax.ListType()) ;
		}
		public String getAgentClassString() { return "TP" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (! (arg0 instanceof Interaction))
				throw new ExtensionException("not an interaction: " + Dump.logoObject(arg0)) ;
			Interaction i = (Interaction) arg0 ;
			Object target = args[1].get() ;
			if (target != null) {
				if ((target.equals(Nobody.class)) || (target instanceof Nobody) || (Dump.logoObject(target).toString().equals("nobody")))
					target = null ;
				else
				if (!((target instanceof Turtle) || (target instanceof Patch)
						|| (target instanceof LogoList)))
					throw new ExtensionException("Second argument of perform-actions ("+Dump.logoObject(target)+") should be a turtle or patch or a list or nobody") ;
			}
			return i.performActions(i.getActions(), (Agent)context.getAgent(), target) ;
		}
	}
}
